{ pkgs, lib, symlinkJoin, runCommand, writeShellApplication, python3, music-tag }:

let
  musictagEnv = python3.withPackages (p: [
    (python3.pkgs.toPythonModule music-tag)
  ]);

  scripts = {
    # sysutils
    nsw = writeShellApplication {
      name = "nsw";
      text = builtins.readFile ./sysutils/nsw.sh;
      runtimeInputs = with pkgs; [ coreutils nix-output-monitor ];
    };

    sc_monitor = writeShellApplication {
      name = "sc_monitor";
      text = builtins.readFile ./sysutils/sc_monitor.sh;
      runtimeInputs = with pkgs; [ coreutils inotify-tools ];
    };

    vr = writeShellApplication {
      name = "vr";
      text = ''
        ${python3}/bin/python3 ${./sysutils/vr.py} "$@"
      '';
    };

    direnv-gc = writeShellApplication {
      name = "direnv-gc";
      text = ''
        ${python3}/bin/python3 ${./sysutils/direnv-gc.py} "$@"
      '';
      runtimeInputs = with pkgs; [ nix ];
    };

    crun = symlinkJoin {
      name = "crun";
      paths = [
        (writeShellApplication {
          name = "crun";
          text = builtins.readFile ./sysutils/crun.sh;
          runtimeInputs = with pkgs; [ ninja coreutils bc ];
        })
        (runCommand "crun-fish-completions" { } ''
          mkdir -p $out/share/fish/vendor_completions.d
          cp ${./sysutils/crun.fish} $out/share/fish/vendor_completions.d/
        '')
      ];
    };

    nix-sync = writeShellApplication {
      name = "nix-sync";
      text = builtins.readFile ./sysutils/nix-sync.sh;
      runtimeInputs = with pkgs; [ jq nix ];
    };

    # musutils
    cue-lint = writeShellApplication {
      name = "cue-lint";
      text = builtins.readFile ./musutils/cue-lint.sh;
    };

    renamer = writeShellApplication {
      name = "renamer";
      text = ''
        ${musictagEnv}/bin/python3 ${./musutils/renamer.py} "$@"
      '';
    };

    cover-export = writeShellApplication {
      name = "cover-export";
      text = ''
        ${musictagEnv}/bin/python3 ${./musutils/cover-export.py} "$@"
      '';
    };

    # misc
    totp = writeShellApplication {
      name = "totp";
      text = builtins.readFile ./misc/totp.sh;
      runtimeInputs = with pkgs; [ openssl coreutils unixtools.xxd ];
    };

    bt-battery = writeShellApplication {
      name = "bt-battery";
      text = builtins.readFile ./misc/bt-battery.sh;
      runtimeInputs = with pkgs; [ gnugrep upower findutils coreutils gawk ];
    };

    totpctl = writeShellApplication {
      name = "totpctl";
      text = builtins.readFile ./misc/totpctl.sh;
      runtimeInputs = with pkgs; [ coreutils gnupg scripts.totp ];
    };

    tun-route = writeShellApplication {
      name = "tun-route";
      text = builtins.readFile ./misc/tun-route.sh;
      runtimeInputs = with pkgs; [ coreutils glibc.getent iproute2 gawk ];
    };
  };

  groups = {
    sysutils = symlinkJoin {
      name = "sharzyscripts-sysutils";
      paths = with scripts; [ nsw sc_monitor vr direnv-gc crun nix-sync ];
    };

    musutils = symlinkJoin {
      name = "sharzyscripts-musutils";
      paths = with scripts; [ cue-lint renamer cover-export ];
    };
  };
in

symlinkJoin
  {
    name = "sharzyscripts";
    paths = builtins.attrValues scripts;
  } // scripts // groups
