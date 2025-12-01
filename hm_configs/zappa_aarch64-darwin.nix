{ pkgs, ... }:

# Note on setting up on macOS:
# You must chsh to /bin/bash because /etc/zprofile is not effected by nix installation, it will clobber our PATH
{
  home.username = "sharzy";
  home.homeDirectory = "/Users/sharzy";
  manual.manpages.enable = false;

  nivium = {
    profile = "full";
    withGraphics = true;
    bashProfileExecFish = true;
  };

  programs.kitty = {
    enable = true;
    settings.font_family = "CaskaydiaCove Nerd Font";
  };

  programs.fish.functions = {
    "tywatch" = ''
      typst compile $argv[1]; or return
      zathura (path change-extension pdf $argv[1]) &
      typst watch $argv[1]
    '';
  };

  programs.git.settings.user.signingKey = "~/.ssh/id_ed25519";

  home.packages = with pkgs; [
    sshfs
    goauthing
    nix-output-monitor

    typst
    tinymist
    mpv
    gh
    nali
    tinyproxy
  ];
}

