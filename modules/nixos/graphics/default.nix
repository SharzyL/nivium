{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.setup.graphics;
in
{
  imports = [
    ./xserver.nix
    ./sway.nix
  ];
  options.setup.graphics = {
    enable = mkEnableOption "graphics base config";

    user = mkOption {
      type = types.str;
    };

    hidpi = mkEnableOption "i3 with hidpi";
  };

  config = mkIf cfg.enable {
    fonts.packages = with pkgs; [
      cascadia-code
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji
      eb-garamond
      inconsolata
      iosevka
      fira-code
      fira
      inter-ss03
      inter
      roboto
      nerd-fonts.caskaydia-cove
      fandol
    ];

    fonts.fontconfig = {
      enable = true;
      antialias = true;
      hinting = {
        enable = false;
      };
      subpixel = {
        rgba = "none";
        lcdfilter = "default";
      };
      defaultFonts.serif = [
        "EB Garamond"
        "Noto Serif CJK SC"
      ];
      defaultFonts.sansSerif = [
        "Inter ss03"
        "Noto Sans CJK SC"
      ];
      defaultFonts.monospace = [
        "CaskaydiaCove Nerd Font Mono"
        "Noto Sans Mono CJK SC"
      ];
      defaultFonts.emoji = [
        "Noto Color Emoji"
      ];
      localConf = builtins.readFile ./fonts.conf;
    };

    services.printing.enable = true;

    i18n = {
      defaultLocale = "en_US.UTF-8";
    };

    xdg.portal = {
      enable = true;
      config = {  # TODO: find out how
        common = {
          default = [ "gtk" ];
        };
      };
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };
}
