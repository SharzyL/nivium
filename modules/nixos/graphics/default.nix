{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nivium.graphics;
in
{
  imports = [
    ./xserver.nix
    ./sway.nix
    ./niri.nix
  ];
  options.nivium.graphics = {
    enable = mkEnableOption "graphics base config";

    user = mkOption {
      type = types.str;
    };

    hidpi.enable = mkEnableOption "i3 with hidpi";
    i3lock.enable = mkEnableOption "i3 with i3lock";
  };

  config = mkIf cfg.enable {
    fonts.packages = with pkgs; [
      cascadia-code
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
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

    programs.i3lock = lib.mkIf cfg.i3lock.enable {
      enable = true;
      u2fSupport = true;
    };
  };
}
