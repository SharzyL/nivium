{ pkgs, config, ... }:

{
  #home.profileDirectory = lib.mkForce "${config.xdg.stateHome}/nix/profile";

  imports = [
    ./homePkgs.nix
  ];

  nivium = {
    withGraphics = true;

    attic-cache = {
      enable = true;
      caches = [{
        substituter = "https://cache.shz.al/shz";
        pubKey = "shz:7ZMa88EJfJD1evQ2eSEt8ekk9yRsHg77DM9RnTsfsPE=";
      }];
    };

    nvim = {
      enable = true;
      lspPackages = true;
    };

    fish = {
      enable = true;
    };

    tmux.enable = true;
    fcitx5-rime.enable = true;
    i3 = {
      enable = true;
      displays = [ "DP-0" "DP-2" ];
      wallpaper = "tank/img/bg/genesis.png";
      extraStartup = [
        { name = "dropbox"; path = "${pkgs.dropbox}/bin/dropbox"; }
        { name = "nicotine"; path = "${pkgs.nicotine-plus}/bin/nicotine-plus"; }
      ];
      extraConfig = ''
        exec_always --no-startup-id env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy ${config.nivium.defaultBrowser}
        exec_always --no-startup-id thunderbird
        exec_always --no-startup-id obsidian
        exec_always --no-startup-id i3-msg 'workspace 0; exec ${config.nivium.defaultTerminal}'
      '';
    };
  };

  systemd.user.services."nicotine" = {
    Service = {
      TemporaryFileSystem = [ "/tank/mus/tlmc_selected/[KodamaSounds]" "~/ws" "~/download" ];
    };
  };

  programs.fish = {
    functions = {
      "sdoc" = ''
        test -n "$argv[1]" && set p "$argv[1]" || set p $HOME/ws/Dropbox/books
        pushd "$p"
        set f (fzf $argv[2..])
        popd
        if test -z "$f"
            echo "No file selected" >&2
            return
        end
        nohup xdg-open "$p/$f" >>/tmp/nohup.out &
      '';

      "plmus" = ''
        set -l files
        for arg in $argv
          set -l mus (string replace -r '\/$' "" "$arg" || true)
          set -a files rsync://sharzy@oomori.d.shz.al/downloads/mus/"$mus"
        end
        echo "pulling '$files'"
        command rsync -rP $files /tank/mus/pt
      '';

      "psmus" = ''
        set -l files
        for arg in $argv
          set -l mus (string replace -r '\/$' "" "$arg" || true)
          set -a files "$mus"
        end
        echo "pushing '$files'"
        command rsync -rP $files rsync://sharzy@oomori.d.shz.al/downloads/
      '';

      "to16b" = ''
        set -l src $argv[0]
        set -l dst $argv[1]
        cp -r "$src" “$dst“
        for f in "$src"/*.flac
          sox -S "$f" -R -G -b 16 "$dst"/(basename "$f") rate -v dither
        end
      '';

      "mktor" = ''
        set -l tracker $argv[1]
        torrenttools create -a $tracker -o $HOME/tmp/$tracker.torrent $argv[2]
      '';

      "tywatch" = ''
        typst compile $argv[1]; or return
        zathura (path change-extension pdf $argv[1]) &
        typst watch $argv[1]
      '';
    };

    shellAbbrs = {
      "mpv" = "mpv --screenshot-directory=$HOME/tmp/_screenshots";
      "mtp" = "music-tag --print";
      "mt" = "music-tag";
      "tt" = "torrenttools";
    };

    shellAliases = {
      "rsync" = "rsync -e 'env DISPLAY=:0 ssh'";
      "logcheck" = "logchecker analyze --no_text";
    };
  };

  systemd.user.tmpfiles.rules = [
    "d %h/tmp - - - 7d -"
    "d %h/tmp/_screenshots - - - 3d -"
  ];

  xdg.userDirs = {
    enable = true;
    desktop = "$HOME/tmp";
    documents = "$HOME/ws/Dropbox/books";
    download = "$HOME/download";
    music = "/tank/mus";
    pictures = "$HOME/download/pic";
    videos = "$HOME/download/video";
    publicShare = "/tank";
    templates = "$HOME/ws/Dropbox";
  };

  programs = {
    nix-index = {
      enable = true;
    };
    broot.enable = true;
  };

  nix.settings = {
    extra-substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://staging.attic.rs/attic-ci"
    ];

    extra-trusted-public-keys = [
      "attic-ci:U5Sey4mUxwBXM3iFapmP0/ogODXywKLRNgRPQpEXxbo="
    ];
  };

  xresources.properties = {
    "Xft.dpi" = 144;
  };

  home.sessionVariables = {
    GDK_DPI_SCALE = "0.7";
  };

  systemd.user.services.sc_monitor = {
    Unit = {
      Description = "copy image from clipboard directory";
      After = [ "systemd-tmpfiles-setup.service" "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.sharzyscripts}/bin/sc_monitor";
      ExecSearchPath = [ "${pkgs.xclip}/bin" ]; # oh hm has no path config
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
