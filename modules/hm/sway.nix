{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nivium.sway;
  defaultStartup = [
    { name = "mako"; path = "${pkgs.mako}/bin/mako"; }
  ];

  run-with-sess-var = pkgs.writeShellScript "run-with-sess-var" ''
    . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
    "$@"
  '';
  systemd-run-app = pkgs.writeShellApplication {
    name = "systemd-run-app";
    text = ''
      name=$(${pkgs.coreutils}/bin/basename "$1")
      id=$(${pkgs.openssl}/bin/openssl rand -hex 4)
      exec ${pkgs.systemd}/bin/systemd-run \
        --user \
        --scope \
        --unit "$name-$id" \
        --slice=app \
        --same-dir \
        --collect \
        --property PartOf=graphical-session.target \
        --property After=graphical-session.target \
        -- ${run-with-sess-var} "$@"
    '';
  };

  dbus-sway-environment = pkgs.writeShellApplication {
    name = "dbus-sway-environment";

    runtimeInputs = with pkgs; [ systemd dbus ];

    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      systemctl --user stop pipewire xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };

  terminal = config.nivium.defaultTerminal;
  locker = "${pkgs.swaylock}/bin/swaylock -c 000000";
  lockerPic = "${pkgs.swaylock}/bin/swaylock -i ${cfg.wallpaper}";
  lockerPicDaemon = "${pkgs.swaylock}/bin/swaylock -f -i ${cfg.wallpaper}";
in
{
  options.nivium.sway = {
    enable = mkEnableOption "use customized sway";
    extraConf = mkOption { type = types.str; default = ""; };
    extraStartup = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption { type = types.str; };
          path = mkOption { type = types.str; };
        };
      });
      default = [ ];
    };
    displays = mkOption { type = types.listOf types.str; };
    wallpaper = mkOption { type = types.nullOr types.str; };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      dbus-sway-environment

      gnome3.adwaita-icon-theme
      dracula-theme

      swayidle
      wofi
      dmenu
      rofi
      swaybg
      mako
      i3-volume
      xdg-utils

      wayshot
      grim
      slurp
      swappy
      wl-clipboard
      cliphist

      systemd-run-app
    ];

    programs.swaylock.enable = true;

    services.swayidle = {
      enable = true;
      events = [
        { event = "before-sleep"; command = lockerPicDaemon; }
      ];
    };

    systemd.user.sessionVariables = {
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    };

    xdg.configFile."swappy/config".text = ''
      [Default]
      save_dir=$HOME/tmp/_screenshots
      save_filename_format=swappy-%Y%m%d-%H%M%S.jpg
    '';

    xdg.configFile."mako/config".text = ''
      font=sans-serif 14
      background-color=#003049
      border-color=#0077b6
      text-color=#eeeeee
      border-radius=8
      padding=8
      width=400

      on-button-middle=dismiss-group
    '';

    wayland.windowManager.sway =
      let
        modifier = "Mod4";
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
          "${modifier}+grave" = "workspace number 0";
          "${modifier}+Shift+grave" = "move container to workspace number 0";
        };

      in
      {
        enable = true;
        wrapperFeatures.gtk = true;
        systemd.enable = true;

        config = {
          inherit modifier;
          bars = [ ];
          fonts = { names = [ "sans-serif" ]; size = 11.0; };

          focus.followMouse = false;
          floating.modifier = modifier;
          window.hideEdgeBorders = "both";
          defaultWorkspace = "workspace number 0";
          inherit terminal;

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

            "${modifier}+bracketleft" = "move workspace to output left";
            "${modifier}+bracketright" = "move workspace to output right";
            "${modifier}+Shift+bracketleft" = "move workspace to output up";
            "${modifier}+Shift+bracketright" = "move workspace to output down";

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
            "${modifier}+r" = "mode resize";

            "${modifier}+Shift+c" = "reload";
            "${modifier}+Shift+r" = "restart";

            "F3" = "exec grim -g \"$(slurp)\" - | swappy -f -";
            "F4" = "exec grim -g \"$(slurp)\" - | wl-copy";

            "${modifier}+Return" = "exec systemd-run-app ${terminal}";
            "${modifier}+Tab" = "exec ${pkgs.wofi}/bin/wofi -show drun";
            "${modifier}+o" = "exec ${pkgs.rofi}/bin/rofi -show run -run-command 'systemd-run-app {cmd}'";

            "--release ${modifier}+Escape" = "exec ${locker}";
            "--release ${modifier}+q" = "exec ${lockerPic}";
            "--release ${modifier}+shift+Escape" = "exec systemctl suspend";

            "XF86MonBrightnessUp" = "exec light -A 5 && light -O";
            "XF86MonBrightnessDown" = "exec light -U 5 && light -O";
            "XF86AudioRaiseVolume" = "exec volume -n up 5";
            "XF86AudioLowerVolume" = "exec volume -n down 5";
            "XF86AudioMute" = "exec volume -n mute";
          });

          startup = [
            { command = "systemd-run-app utools"; }
            { command = "systemd-run-app dbus-sway-environment"; }
            { command = "systemd-run-app wl-paste --watch cliphist store"; }
          ];

          assigns = {
            "1" = [{ app_id = config.nivium.defaultBrowser; }];
            "3" = [{ app_id = "obsidian"; } { app_id = "thunderbird"; }];
          };
          window.commands =
            let
              makeFloat = criteria: { inherit criteria; command = "floating enable"; };
            in
            map makeFloat [
              { class = "Anki"; }
              { class = "Pavucontrol"; }
              { class = "Pavucontrol"; }
              { window_role = "pop-up"; }
              { window_role = "task_dialog"; }
              { class = "flameshot"; }
            ];
          colors = {
            focused = {
              border = "#003049";
              background = "#003049";
              text = "#eeeeee";
              indicator = "#0077b6";
              childBorder = "#0077b6";
            };
            focusedInactive = {
              border = "#333333";
              background = "#333333";
              text = "#ffffff";
              indicator = "#333333";
              childBorder = "#333333";
            };
            unfocused = {
              border = "#333333";
              background = "#222222";
              text = "#888888";
              indicator = "#292d2e";
              childBorder = "#222222";
            };
            urgent = {
              border = "#ef233c";
              background = "#ef233c";
              text = "#ffffff";
              indicator = "#900000";
              childBorder = "#0c0c0c";
            };
          };
        };

        extraConfig = ''
          show_marks yes
          focus_follows_mouse no

          input * {
            xkb_layout "us"
            xkb_options "caps:super"
          }

          input type:touchpad {
            tap enabled
            natural_scroll enabled
            pointer_accel 1
          }

          ${lib.optionalString (cfg.wallpaper != null) "output * bg ${cfg.wallpaper} fill"}

          ${cfg.extraConf}
        '';
      };

    programs.waybar = {
      enable = true;
      systemd.enable = true;
      style = ./resource/waybar.style.css;
      settings = {
        mainBar = {
          layer = "bottom";
          position = "bottom";
          height = 32;
          output = cfg.displays;
          modules-right = [ "battery" "custom/trackpad" "backlight" "pulseaudio" "disk" "cpu" "memory" "network" "clock" "tray" ];
          modules-left = [ "sway/workspaces" "sway/mode" "sway/window" ];
          tray = {
            spacing = 10;
          };
          clock = {
            format = "{:%Y-%m-%d %a %H:%M:%S}";
            interval = 1;
          };
          battery = {
            adapter = "ADP1";
            bat = "BAT0";
            interval = 1;
            fullat = 95;
            states = {
              normal = 90;
              warning = 40;
              critical = 20;
            };
            format = "{icon}   {capacity}% (-{power}W)";
            format-charging = "   {capacity}% (+{power}W)";
            format-plugged = "   {capacity}% (+{power}W)";
            format-icons = [ "" "" "" "" "" ];
          };
          network = {
            format-wifi = "   {essid} {ipaddr} (↑{bandwidthUpBytes} ↓{bandwidthDownBytes})";
            format-ethernet = "󰈀  {ipaddr} (↑{bandwidthUpBytes} ↓{bandwidthDownBytes})";
            format-disconnected = "Disconnected ⚠";
          };
          backlight = {
            format = "{icon}  {}%";
            format-icons = [ "" "" "" "" "" "" "" "" "" ];
            on-scroll-up = "light -U 1 && light -O";
            on-scroll-down = "light -A 1 && light -O";
          };
          disk = {
            format = "󰋊  {used}";
            path = "/nix/store";
          };
          cpu = {
            interval = 1;
            format = "  {usage}%";
            states = {
              good = 0;
              normal = 5;
              warning = 60;
              critical = 80;
            };
          };
          memory = {
            interval = 1;
            format = "  {}%";
            states = {
              good = 0;
              normal = 40;
              warning = 80;
              critical = 95;
            };
          };
          pulseaudio = {
            format = "{icon}  {volume}%";
            format-muted = "  muted";
            format-icons = {
              default = [ "" "" "" ];
            };
            on-scroll-up = "volume down 1";
            on-scroll-down = "volume up 1";
            on-click = "volume mute";
            on-click-right = "pavucontrol";
          };

          "custom/trackpad" = {
            exec = "${pkgs.sharzyscripts}/bin/bt-battery --show_waybar_icon 'Magic Trackpad' ";
            return-type = "json";
            interval = 5;
            format = "󰀵  {percentage}%";
          };

          # the battery percentage is not working now, not using it now
          bluetooth = {
            format = "  {status}";
            format-disabled = "";
            format-connected = " {num_connections} connected";
            format-connected-battery = " {device_alias} {device_battery_percentage}%";
            tooltip-format = "{controller_alias}\t{controller_address}";
            tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
            tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          };
        };
      };
    };

    systemd.user.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    systemd.user.services = (
      listToAttrs (map
        (
          { name, path }: nameValuePair name {
            Unit = {
              Description = "automatic starting ${name} on sway startup";
              After = [ "graphical-session-pre.target" ];
              PartOf = [ "graphical-session.target" ];
            };
            Install = { WantedBy = [ "graphical-session.target" ]; };
            Service = {
              ExecStart = path;
            };
          }
        )
        (defaultStartup ++ cfg.extraStartup))
    ) //
    {
      waybar.Service.Environment = [
        "PATH=${lib.makeBinPath (with pkgs; [
          i3-volume
          pavucontrol
          pulseaudio
          gawk

          light
        ])}"
      ];

      waybar.Install.WantedBy = [ "sway-session.target" ];
      fcitx5-daemon.Install.WantedBy = [ "sway-session.target" ];

      # to avoid repeated restarting after terminating sway
      waybar.Service.Restart = lib.mkForce "no";
    };
  };
}
