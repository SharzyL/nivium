{ pkgs, ... }:

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

    niri = {
      enable = true;
      displays = [ "eDP-1" "HDMI-A-1" ];
      configFile = ./niri.kdl;
      extraStartup = [
        { name = "dropbox"; path = "${pkgs.dropbox}/bin/dropbox"; }
        { name = "swaybg"; path = "${pkgs.swaybg}/bin/swaybg -i /home/sharzy/download/pic/wallpaper.jpg"; }

        { name = "kitty"; path = "${pkgs.kitty}/bin/kitty"; }
        { name = "firefox"; path = "${pkgs.firefox}/bin/firefox"; }
        { name = "thunderbird"; path = "${pkgs.thunderbird}/bin/thunderbird"; }
        { name = "obsidian"; path = "${pkgs.obsidian}/bin/obsidian"; }
        { name = "telegram"; path = "${pkgs.telegram-desktop}/bin/Telegram"; }
      ];
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
