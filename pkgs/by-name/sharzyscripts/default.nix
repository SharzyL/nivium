{ pkgs, symlinkJoin, writeShellApplication, python3, music-tag }:

let
  totp = writeShellApplication {
    name = "totp";
    text = builtins.readFile ./sh/totp.sh;
    runtimeInputs = with pkgs; [ openssl coreutils unixtools.xxd ];
  };
  musictagEnv = python3.withPackages (p: [
    (python3.pkgs.toPythonModule music-tag)
  ]);
in

symlinkJoin {
  name = "sharzyscripts";

  paths = [
    totp

    (writeShellApplication {
      name = "bt-battery";
      text = builtins.readFile ./sh/bt-battery.sh;
      runtimeInputs = with pkgs; [ gnugrep upower findutils coreutils gawk ];
    })

    (writeShellApplication {
      name = "nsw";
      text = builtins.readFile ./sh/nsw.sh;
      runtimeInputs = with pkgs; [ coreutils nix-output-monitor ];
    })

    (writeShellApplication {
      name = "totpctl";
      text = builtins.readFile ./sh/totpctl.sh;
      runtimeInputs = with pkgs; [ coreutils gnupg totp ];
    })

    (writeShellApplication {
      name = "tun-route";
      text = builtins.readFile ./sh/tun-route.sh;
      runtimeInputs = with pkgs; [ coreutils glibc.getent iproute2 gawk ];
    })

    (writeShellApplication {
      name = "sc_monitor";
      text = builtins.readFile ./sh/sc_monitor.sh;
      runtimeInputs = with pkgs; [ coreutils inotify-tools ];
    })

    (writeShellApplication {
      name = "cue-lint";
      text = builtins.readFile ./sh/cue-lint.sh;
    })

    (writeShellApplication {
      name = "renamer";
      text = ''
        ${musictagEnv}/bin/python3 ${./py/renamer.py} "$@"
      '';
    })

    (writeShellApplication {
      name = "cover-export";
      text = ''
        ${musictagEnv}/bin/python3 ${./py/cover-export.py} "$@"
      '';
    })

    (writeShellApplication {
      name = "vr";
      text = ''
        ${musictagEnv}/bin/python3 ${./py/vr.py} "$@"
      '';
    })

    (writeShellApplication {
      name = "csync";
      text =
        let
          pyEnv = python3.withPackages (ps: with ps; [
            loguru
            pyinotify
            pathspec
          ]);
        in
        ''
          ${pyEnv}/bin/python3 ${./py/csync.py} "$@"
        '';
    })

  ];
}

