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

  home.packages = with pkgs; [
    sing-box
    rclone
    sshfs
    goauthing
    python-ddns
    nix-output-monitor

    alacritty

    tailscale
    colmena

    # tex
    python3.pkgs.pygments
    latexrun
    zathura
    # (texlive.combine {
    #   inherit (texlive) scheme-full;
    # })

    openssh
    typst
    tinymist
  ];
}

