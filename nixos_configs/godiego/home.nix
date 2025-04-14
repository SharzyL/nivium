{ pkgs, config, ... }:

{
  imports = [
    ./homePkgs.nix
  ];

  nivium = {
    withGraphics = true;

    nvim = {
      enable = true;
      lspPackages = true;
    };

    fish = {
      enable = true;
    };

    attic-cache = {
      enable = true;
      caches = [{
        substituter = "https://cache.shz.al/shz";
        pubKey = "shz:7ZMa88EJfJD1evQ2eSEt8ekk9yRsHg77DM9RnTsfsPE=";
      }];
    };

    # sway = {
    #   enable = true;
    #   displays = [ "eDP-1" "DP-3" "HDMI-A-1" ];
    #   wallpaper = "/home/sharzy/download/pic/wallpaper.jpg";
    #   extraConf = ''
    #     output eDP-1 scale 1.5 position 0 960
    #     output DP-3 scale 1 position 2048 0 transform 270
    #
    #     input "10182:291:GXTP7936:00_27C6:0123" map_to_output eDP-1
    #
    #     exec ${config.nivium.defaultBrowser}
    #     exec thunderbird
    #     exec obsidian
    #     exec swaymsg 'workspace 0; exec ${config.nivium.defaultTerminal}'
    #   '';
    #   extraStartup = [
    #     { name = "dropbox"; path = "${pkgs.dropbox}/bin/dropbox"; }
    #   ];
    # };

    i3 = {
      enable = true;
      displays = [ "eDP-1" "DP-3" "HDMI-A-1" ];
      wallpaper = "/home/sharzy/download/pic/wallpaper.jpg";
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

    tmux.enable = true;

    fcitx5-rime.enable = true;
  };

  programs.fish = {
    shellAbbrs = {
        "mpv" = "mpv --screenshot-directory=$HOME/tmp/_screenshots";
    };
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
    };
  };

  systemd.user.tmpfiles.rules = [
    "d %h/tmp - - - 0 -"
    "d %h/tmp/_screenshots - - - 3d -"
  ];

  systemd.user.services.sc_monitor = {
    Unit = {
      Description = "copy image from clipboard directory";
      After = [ "systemd-tmpfiles-nivium.service" "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.sharzyscripts}/bin/sc_monitor";
      ExecSearchPath = [ "${pkgs.wl-clipboard}/bin" ];  # oh hm has no path config
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.userDirs = {
    enable = true;
    desktop = "$HOME/tmp";
    documents = "$HOME/ws/Dropbox/books";
    download = "$HOME/download";
    music = "/tank/mus";
    pictures = "$HOME/download/img";
    videos = "$HOME/download/video";
    publicShare = "$HOME";
    templates = "$HOME";
  };

  programs.nix-index = {
    enable = true;
  };

  gtk.font.size = 12;
}
