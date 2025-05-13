{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nivium.i3;
  defaultStartup = [ ];
in
{
  options.nivium.i3 = {
    enable = mkEnableOption "use customized i3";
    extraConfig = mkOption { type = types.str; default = ""; };
    extraStartup = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption { type = types.str; };
          path = mkOption { type = types.str; };
        };
      });
    };
    polybar = mkOption {
      type = types.submodule {
        options = {
          heightPt = mkOption { type = types.int; default = 20; };
          fontSize = mkOption { type = types.int; default = 11; };
          emojiScale = mkOption { type = types.int; default = 10; };
          override = mkOption { type = types.attrs; default = { }; };
        };
      };
      default = { };
    };
    displays = mkOption { type = types.listOf types.str; };
    wallpaper = mkOption { type = types.nullOr types.str; };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      libnotify
      rofi
      dmenu
      scrot
      i3-volume
      # we must use i3lock provided by nixos for its security wrapper
    ];

    xsession.windowManager.i3 =
      let
        modifier = "Mod4";
        terminal = config.nivium.defaultTerminal;
        locker = "i3lock -c 000000";
        polybar = "systemctl --user start polybar";
        ns = "--no-startup-id";

        workspaceShortcuts = with builtins; (listToAttrs (concatMap
          (i:
            let
              ii = toString i;
              ni = toString (if i == 10 then 0 else i);
              fi = toString (10 + i);
            in
            [
              { name = "${modifier}+${ni}"; value = "workspace number ${ii}"; }
              { name = "${modifier}+F${ii}"; value = "workspace number ${fi}"; }
              { name = "${modifier}+Shift+${ni}"; value = "move container to workspace number ${ii}"; }
              { name = "${modifier}+Shift+F${ii}"; value = "move container to workspace number ${fi}"; }
            ]
          ) [ 1 2 3 4 5 6 6 8 9 10 ]))
        // {
          " ${modifier}+grave" = "workspace number 0"; # use a space to promote it to first
          "${modifier}+Shift+grave" = "move container to workspace number 0";
        };

      in
      {
        enable = true;
        config = {
          inherit modifier;
          fonts = { names = [ "sans-serif" ]; size = 11.0; };

          focus.followMouse = false;
          floating.modifier = modifier;
          window.hideEdgeBorders = "both";
          terminal = config.nivium.defaultTerminal;

          keybindings = lib.mkOptionDefault (workspaceShortcuts // {
            "${modifier}+k" = "focus up";
            "${modifier}+Up" = "focus up";
            "${modifier}+j" = "focus down";
            "${modifier}+Down" = "focus down";
            "${modifier}+h" = "focus left";
            "${modifier}+Left" = "focus left";
            "${modifier}+l" = "focus right";
            "${modifier}+Right" = "focus right";
            "Mod1+Tab" = "workspace back_and_forth";

            "${modifier}+Shift+k" = "move up";
            "${modifier}+Shift+Up" = "move up";
            "${modifier}+Shift+j" = "move down";
            "${modifier}+Shift+Down" = "move down";
            "${modifier}+Shift+h" = "move left";
            "${modifier}+Shift+Left" = "move left";
            "${modifier}+Shift+l" = "move right";
            "${modifier}+Shift+Right" = "move right";

            "${modifier}+braceleft" = "move workspace to output left";
            "${modifier}+braceright" = "move workspace to output right";
            "${modifier}+Shift+braceleft" = "move workspace to output up";
            "${modifier}+Shift+braceright" = "move workspace to output down";

            "${modifier}+u" = "[urgent=latest] focus";
            "${modifier}+semicolon" = "split h";
            "${modifier}+v" = "split v";
            "${modifier}+Shift+f" = "fullscreen toggle";
            "${modifier}+f" = "floating toggle";
            "${modifier}+s" = "layout stacking";
            "${modifier}+w" = "layout tabbed";
            "${modifier}+e" = "layout toggle split";

            "${modifier}+space" = "focus mode_toggle";
            "${modifier}+p" = "focus parent";
            "${modifier}+c" = "focus child";
            "${modifier}+minus" = "move scratchpad";
            "${modifier}+plus" = "scratchpad show";
            "${modifier}+x" = "kill";

            "${modifier}+Shift+c" = "reload";
            "${modifier}+Shift+r" = "restart";

            "F4" = "exec ${pkgs.flameshot}/bin/flameshot gui";
            "F3" = "exec ${pkgs.scrot}/bin/scrot -u -f 'tmp/_screenshots/scrot_%Y-%m-%d__%h-%m-%s.png'";
            "${modifier}+Return" = "exec ${terminal}";
            "${modifier}+Tab" = "exec ${pkgs.rofi}/bin/rofi -show window";
            "${modifier}+o" = "exec i3-dmenu-desktop";

            "--release ${modifier}+Escape" = "exec ${locker}";
            "--release ${modifier}+shift+Escape" = "exec systemctl suspend";

            "XF86MonBrightnessUp" = "exec ${ns} xbacklight -inc 5";
            "XF86MonBrightnessDown" = "exec ${ns} xbacklight -dec 5";
            "XF86AudioRaiseVolume" = "exec ${ns} volume -n up 5";
            "XF86AudioLowerVolume" = "exec ${ns} volume -n down 5";
            "XF86AudioMute" = "exec ${ns} volume -n mute";
          });

          startup =
            let
              silentStart = app: { command = app; notification = false; };
            in
            builtins.map
              silentStart
              ([
                "xset s off" # disable screensavers
                "xset -b" # disable beep
                "xset -dpms" # disable dpms
                "env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy utools" # workaround for fcitx issue
                "${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock -- ${locker} --nofork"
                polybar
              ] ++ (lib.optional (cfg.wallpaper != null) "feh --no-fehbg --bg-scale ${cfg.wallpaper}"));

          window.commands =
            (
              let
                makeFloat = criteria: { inherit criteria; command = "floating enable"; };
              in
              map makeFloat [
                { class = "Anki"; }
                { class = "Pavucontrol"; }
                { class = "Pavucontrol"; }
                { window_role = "pop-up"; }
                { window_role = "task_dialog"; }
                { title = "*nagbar-cmd*"; }
                { class = "feh"; }
                { class = "flameshot"; }
              ]
            ) ++ [
              { criteria = { class = config.nivium.defaultBrowser; }; command = "move to workspace 1"; }
              { criteria = { class = "thunderbird"; }; command = "move to workspace 3"; }
              { criteria = { class = "obsidian"; }; command = "move to workspace 3"; }
              { criteria = { instance = "org.nicotine_plus.Nicotine"; }; command = "move to workspace 5"; }
              { criteria = { instance = "telegram-desktop"; title = "メディアビューア"; }; command = "layout tabbed"; }
            ];

          bars = [ ]; # disable i3bar
        };

        extraConfig = ''
          show_marks yes
          focus_follows_mouse no
        '' + cfg.extraConfig;
      };

    services.polybar = {
      enable = true;
      package = pkgs.polybarFull;
      script =
        let
          makeStartupScript = display: ''
            polybar "bar-${display}" >> /tmp/polybar.log &
          '';
        in
        ''
          ${pkgs.killall}/bin/killall -q polybar
          ${builtins.concatStringsSep "\n" (
            map makeStartupScript cfg.displays
          )}
        '';
      config =
        let
          makeBar = display: nameValuePair "bar/bar-${display}" {
            "inherit" = "bar/default";
            monitor = display;
          };
          bars = with builtins; listToAttrs (map makeBar cfg.displays);
          basic-bar = import ./resource/polybar-base.nix cfg.polybar;
          extraModules =
            {
              "module/trackpad-power" = {
                type = "custom/script";
                interval = 600;
                exec = "${pkgs.sharzyscripts}/bin/bt-battery --show_polybar_icon 'Magic Trackpad' ";
              };
            };
        in
        (lib.recursiveUpdate basic-bar cfg.polybar.override) // bars // extraModules;
    };

    services.dunst = {
      enable = true;
      settings = import ./resource/dunstrc.nix;
    };

    services.picom = {
      enable = true;

      # to prevent screen tearing on Nvidia driver
      vSync = true;
      backend = "glx";

      settings = {
        # to prevent showing notif on lockscreen
        unredir-if-possible = true;

        # to prevent tearing on fullscreen
        unredir-if-possible-exclude = "class_g = 'mpv'";
      };
    };

    services.flameshot = {
      enable = true;
    };

    systemd.user.services = listToAttrs (map
      (
        { name, path }: nameValuePair name {
          Unit = {
            Description = "automatic starting ${name} on i3 startup";
            After = [ "graphical-session-pre.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Install = { WantedBy = [ "graphical-session.target" ]; };
          Service = {
            ExecStart = path;
            Restart = "on-failure";
          };
        }
      )
      (defaultStartup ++ cfg.extraStartup));
  };
}
