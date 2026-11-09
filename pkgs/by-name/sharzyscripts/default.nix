{ pkgs, lib, symlinkJoin, runCommand, writeShellApplication, python3, music-tag }:

let
  musictagEnv = python3.withPackages (p: [
    (python3.pkgs.toPythonModule music-tag)
  ]);

  # writeShellApplication with the platform-specific runtime inputs listed apart:
  # the script is only available where all of them are
  writePlatformScript = { platformInputs, runtimeInputs ? [ ], ... }@args:
    writeShellApplication (removeAttrs args [ "platformInputs" ] // {
      runtimeInputs = runtimeInputs ++ platformInputs;
      meta.platforms = lib.foldl' (ps: p: lib.intersectLists ps p.meta.platforms) lib.platforms.all platformInputs;
    });

  scripts = {
    # sysutils
    # nix and ssh come from the system: the script talks to the running daemon
    # and to the user's ssh config; iets and nom are picked up from PATH when present
    nsw = writeShellApplication {
      name = "nsw";
      text = ''
        exec ${python3.withPackages (p: [ p.pyyaml ])}/bin/python3 ${../../../nsw/nsw.py} "$@"
      '';
      runtimeInputs = with pkgs; [ coreutils ];
    };

    sc_monitor = writePlatformScript {
      name = "sc_monitor";
      text = builtins.readFile ./sysutils/sc_monitor.sh;
      runtimeInputs = with pkgs; [ coreutils ];
      platformInputs = with pkgs; [ inotify-tools ];
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
      runtimeInputs = with pkgs; [ jq nix curl gnused coreutils ];
    };

    term-bg = writeShellApplication {
      name = "term-bg";
      text = builtins.readFile ./sysutils/term-bg.sh;
      runtimeInputs = with pkgs; [ coreutils gawk ];
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

    bt-battery = writePlatformScript {
      name = "bt-battery";
      text = builtins.readFile ./misc/bt-battery.sh;
      runtimeInputs = with pkgs; [ gnugrep findutils coreutils gawk ];
      platformInputs = with pkgs; [ upower ];
    };

    totpctl = writeShellApplication {
      name = "totpctl";
      text = builtins.readFile ./misc/totpctl.sh;
      runtimeInputs = with pkgs; [ coreutils gnupg scripts.totp ];
    };

    tun-route = writePlatformScript {
      name = "tun-route";
      text = builtins.readFile ./misc/tun-route.sh;
      runtimeInputs = with pkgs; [ coreutils gawk ];
      platformInputs = with pkgs; [ glibc.getent iproute2 ];
    };
  };

  # drop scripts whose platformInputs are unavailable on the host
  available = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform);

  groups = {
    sysutils = symlinkJoin {
      name = "sharzyscripts-sysutils";
      paths = available (with scripts; [ nsw sc_monitor vr direnv-gc crun nix-sync term-bg ]);
    };

    musutils = symlinkJoin {
      name = "sharzyscripts-musutils";
      paths = available (with scripts; [ cue-lint renamer cover-export ]);
    };
  };
in

symlinkJoin
  {
    name = "sharzyscripts";
    paths = available (builtins.attrValues scripts);
  } // scripts // groups
