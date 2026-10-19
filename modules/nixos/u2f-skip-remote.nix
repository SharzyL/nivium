{ config, lib, pkgs, ... }:

let
  cfg = config.nivium.u2f.skipRemote;

  # Exits 0 when the PAM caller runs inside a remote session, which the rule
  # below turns into skipping pam_u2f. Remote is judged from the process tree:
  # an sshd ancestor, or a multiplexer server. Those servers are only ever
  # started remotely here, and a pane's ancestry leads to the server rather than
  # to whoever is attached, so they have to count on their own.
  #
  # Processes are named by their comm from /proc/PID/stat, not by readlink on
  # /proc/PID/exe: that needs ptrace access to the target, which the mixed
  # credentials pam_exec inherits from sudo do not reliably have, while stat is
  # readable by anyone. A process can rename its comm, but faking a remote
  # session only gets the password prompt instead of the key.
  isRemote = pkgs.writeShellScript "pam-u2f-is-remote" ''
    pid=$PPID
    while [ "$pid" -gt 1 ]; do
      stat=$(<"/proc/$pid/stat") || exit 1
      # "PID (COMM) STATE PPID ...", where COMM may itself contain spaces and
      # parentheses: cut at the first "(" and the last ")"
      comm=''${stat#*(}
      comm=''${comm%)*}
      # comm is truncated to 15 characters, hence wezterm-mux-ser
      case $comm in
        sshd | sshd-session | "tmux: server" | wezterm-mux-ser) exit 0 ;;
      esac
      read -r _ pid _ <<<"''${stat##*) }"
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
        service with u2f.enable set would recurse into security.pam.services.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Skipping a sufficient module only ever falls back to the password. With
    # u2f as a required second factor, skipping it would drop that factor.
    assertions = map
      (name:
        let svc = config.security.pam.services.${name}; in {
          assertion = svc.u2f.enable && svc.u2f.control == "sufficient";
          message = "nivium.u2f.skipRemote: PAM service ${name} must have u2f.enable with control \"sufficient\"";
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
