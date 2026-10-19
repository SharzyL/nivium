{ config, lib, pkgs, ... }:

let
  cfg = config.nivium.u2f.skipRemote;

  # Exits 0 when the PAM caller runs inside a remote session, which the rule
  # below turns into skipping pam_u2f. Remote is judged from the process tree:
  # an sshd ancestor, or a multiplexer server. Those servers are only ever
  # started remotely here, and a pane's ancestry leads to the server rather than
  # to whoever is attached, so they have to count on their own.
  #
  # pam_exec runs this with the caller's real uid, so it can only see the
  # caller's own processes. That is enough: the session's sshd-session, the
  # tmux server and the wezterm mux server all run as the user.
  isRemote = pkgs.writeShellScript "pam-u2f-is-remote" ''
    pid=$PPID
    while [ "$pid" -gt 1 ]; do
      exe=$(${pkgs.coreutils}/bin/readlink "/proc/$pid/exe" 2>/dev/null) || exe=
      name=''${exe##*/}
      # nix wrappers rename the real binary to .NAME-wrapped
      name=''${name#.}
      name=''${name%-wrapped}
      case $name in
        sshd | sshd-session | tmux | wezterm-mux-server) exit 0 ;;
      esac
      stat=$(<"/proc/$pid/stat") || exit 1
      # the command name in parentheses may contain spaces; ppid is the second
      # field after it
      stat=''${stat##*) }
      read -r _ pid _ <<<"$stat"
    done
    exit 1
  '';
in
{
  options.nivium.u2f.skipRemote = {
    enable = lib.mkEnableOption ''
      skipping pam_u2f, straight to the password prompt, when authenticating
      from an ssh session or a terminal multiplexer, where nobody can touch the
      key
    '';
    services = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ "sudo" ];
      description = ''
        PAM services to apply this to. An explicit list: deriving it from every
        service with u2fAuth set would recurse into security.pam.services.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Skipping a sufficient module only ever falls back to the password. With
    # u2f as a required second factor, skipping it would drop that factor.
    assertions = map
      (name:
        let svc = config.security.pam.services.${name}; in {
          assertion = svc.u2fAuth && svc.rules.auth.u2f.control == "sufficient";
          message = "nivium.u2f.skipRemote: PAM service ${name} must have u2fAuth with control \"sufficient\"";
        })
      cfg.services;

    security.pam.services = lib.genAttrs cfg.services (name: {
      rules.auth.u2f-skip-remote = {
        # directly above pam_u2f, so that success=1 skips exactly that line
        order = config.security.pam.services.${name}.rules.auth.u2f.order - 1;
        control = "[success=1 default=ignore]";
        modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
        args = [ "quiet" "${isRemote}" ];
      };
    });
  };
}
