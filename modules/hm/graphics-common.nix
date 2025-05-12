{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nivium;

  dir-openner = pkgs.makeDesktopItem {
    name = "dir-openner";
    desktopName = "Directory Openner";
    mimeTypes = [ "inode/directory" ];
    exec = "${cfg.defaultTerminal} yazi";
  };
in
{
  options.nivium = with lib.types; {
    withGraphics = lib.mkEnableOption "graphics";
    defaultBrowser = lib.mkOption { type = str; default = "firefox"; };
    defaultTerminal = lib.mkOption { type = str; default = "kitty"; };
  };

  config = mkIf (config.nivium.i3.enable || config.nivium.sway.enable) {
    assertions = [
      { assertion = cfg.withGraphics; message = "You should enable graphics to use wm"; }
    ];

    xsession.enable = true;
    xresources.path = "${config.xdg.configHome}/X11/xresources";
    xsession.profilePath = ".config/X11/xprofile";
    gtk.gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";

    home.packages = [
      pkgs.${cfg.defaultBrowser}
      pkgs.${cfg.defaultTerminal}
      dir-openner

      pkgs.geeqie
    ];

    programs.alacritty = lib.mkIf (cfg.defaultTerminal == "alacritty") {
      enable = true;
      settings = {
        window.dynamic_padding = true;
        font.normal.family = "monospace";
        shell = {
          program = "${pkgs.tmux}/bin/tmux";
        };
        scrolling.multiplier = 15;
      };
    };

    # handle the rest in ./kitty.nix
    programs.kitty.enable = lib.mkIf (cfg.defaultTerminal == "kitty") true;

    systemd.user.sessionVariables = {
      MOZ_USE_XINPUT2 = "1";
    };

    qt = {
      enable = true;
      style.name = "breeze";
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "image/jpeg" = "org.geeqie.Geeqie.desktop";
        "image/png" = "org.geeqie.Geeqie.desktop";
        "image/gif" = "org.geeqie.Geeqie.desktop";
        "image/webp" = "org.geeqie.Geeqie.desktop";
        "image/heif" = "org.geeqie.Geeqie.desktop";

        "application/pdf" = "${cfg.defaultBrowser}.desktop";
        "text/html" = "${cfg.defaultBrowser}.desktop";
        "text/plain" = "code.desktop";
        "x-scheme-handler/http" = "${cfg.defaultBrowser}.desktop";
        "x-scheme-handler/https" = "${cfg.defaultBrowser}.desktop";
        "x-scheme-handler/tg" = "org.telegram.desktop.desktop";

        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "wps-office-wps.desktop";
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "wps-office-wpp.desktop";
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "wps-office-et.desktop";

        "inode/directory" = "dir-openner.desktop";
      };
    };

    home.file.".Mathematica/Kernel/init.m" = mkIf
      (lib.any (p: lib.hasPrefix p.name "methematics-") config.home.packages)
      {
        text = ''
          With[{dir = $UserDocumentsDirectory <> "/Wolfram Mathematica"},
            If[DirectoryQ[dir], DeleteDirectory[dir]]
          ]
        '';
      };

    gtk = {
      enable = true;
      theme = {
        package = pkgs.kdePackages.breeze-gtk;
        name = "Breeze";
      };
      iconTheme = {
        package = pkgs.numix-icon-theme-circle;
        name = "Numix-Circle";
      };
      cursorTheme = {
        package = pkgs.numix-cursor-theme;
        name = "Numix-Cursor";
      };
      font = {
        package = pkgs.inter-ss03;
        name = "Inter ss03";
        size = lib.mkDefault 14; # though we only want to set fontsize, we cannot only set fontsize
      };
    };
  };
}
