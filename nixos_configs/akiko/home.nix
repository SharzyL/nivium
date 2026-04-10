{ pkgs, ... }:

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
    niri = {
      enable = true;
      displays = [ "DP-1" "DP-2" ];
      configFile = ./niri.kdl;
      extraStartup = [
        { name = "dropbox"; path = "${pkgs.dropbox}/bin/dropbox"; }
        { name = "swaybg"; path = "${pkgs.swaybg}/bin/swaybg -i tank/sharzy/img/bg/koufu.jpg"; }

        { name = "kitty"; path = "${pkgs.kitty}/bin/kitty"; }
        { name = "firefox"; path = "${pkgs.firefox}/bin/firefox"; }
        { name = "thunderbird"; path = "${pkgs.thunderbird}/bin/thunderbird"; }
        { name = "obsidian"; path = "${pkgs.obsidian}/bin/obsidian"; }
        { name = "telegram"; path = "${pkgs.telegram-desktop}/bin/Telegram"; }
        { name = "nicotine"; path = "${pkgs.nicotine-plus}/bin/nicotine-plus"; }
      ];
    };
  };

  systemd.user.services."autostart-nicotine" = {
    Service = {
      TemporaryFileSystem = [ "/tank/mus/tlmc_selected/[KodamaSounds]" "%h/ws" "%h/download" ];
    };
  };

  systemd.user.services."autostart-firefox" = {
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  programs.obs-studio.enable = true;

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

    };

    shellAbbrs = {
      "mpv" = "mpv --screenshot-directory=$HOME/tmp/_screenshots";
      "mtp" = "music-tag --print";
      "mt" = "music-tag";
      "tt" = "torrenttools";
      "tyw" = "typst watch --open zathura";
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
    # https://gitlab.gnome.org/GNOME/nautilus/-/issues/4014
    templates = "$HOME/tmp/templates";
  };

  programs = {
    nix-index = {
      enable = true;
    };
    broot.enable = true;
  };

  nix.settings = {
    extra-substituters = [
      # "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      # "https://staging.attic.rs/attic-ci"
    ];

    extra-trusted-public-keys = [
      "attic-ci:U5Sey4mUxwBXM3iFapmP0/ogODXywKLRNgRPQpEXxbo="
    ];
  };

  home.sessionVariables = {
    GDK_DPI_SCALE = "0.7";
  };
}
