{ config, pkgs, lib, ... }:

let
  cfg = config.nivium.niri;

  defaultStartup = [
    { name = "fcitx5"; path = "${pkgs.fcitx5}/bin/fcitx5"; }
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

  dbus-niri-environment = pkgs.writeShellApplication {
    name = "dbus-niri-environment";

    runtimeInputs = with pkgs; [ systemd dbus ];

    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=niri
      systemctl --user stop pipewire xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };
in
{
  options.nivium.niri = with lib; {
    enable = mkEnableOption "use customized niri";
    configFile = mkOption { type = types.path; };
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
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."niri/config.kdl".source = cfg.configFile;
    programs = {
      fuzzel.enable = true;
      swaylock = {
        enable = true;
        settings = {
          color = "000000";
          indicator-idle--visible = false;
        };
      };
    };

    services.polkit-gnome.enable = true;

    home.packages = with pkgs; [
      dbus-niri-environment

      dracula-theme

      xwayland-satellite
      i3-volume
      xdg-utils
      libnotify

      grim
      slurp
      swappy
      wl-clipboard
      cliphist
      wev

      swaybg
      swaylock

      systemd-run-app
    ];

    services.swayidle = {
      enable = true;
      timeouts = [
        { timeout = 1200; command = "${pkgs.swaylock}/bin/swaylock -fF"; }
        { timeout = 1800; command = "${pkgs.niri}/bin/niri msg action power-off-monitors"; }
      ];
    };

    services.swaync = {
      enable = true;
      settings = {
        timeout = 15;
        timeout-low = 5;
        timeout-critical = 60;
      };
      style = ./resource/swaync.style.css;
    };

    systemd.user.sessionVariables = {
      QT_QPA_PLATFORM = "wayland";
      NIXOS_OZONE_WL = "1";
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
          modules-right = [ "battery" "backlight" "pulseaudio" "disk" "cpu" "memory" "network#eth" "network#wlan" "custom/notif" "clock" "tray" ];
          modules-left = [ "niri/workspaces" "niri/workspace-overview" "niri/window" ];
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
          "network#eth" = {
            interface = "enp*";
            interval = 1;
            format-ethernet = "󰈀  {ipaddr} (↑{bandwidthUpBytes} ↓{bandwidthDownBytes})";
            format-disconnected = "Disconnected ⚠";
          };
          "network#wlan" = {
            interface = "wlan*";
            interval = 1;
            format = "   {essid} {ipaddr} (↑{bandwidthUpBytes} ↓{bandwidthDownBytes} {signalStrength}%)";
            format-disconnected = "";
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
            on-scroll-up = "volume up 2";
            on-scroll-down = "volume down 2";
            on-click = "volume mute";
            on-click-right = "pavucontrol";
          };
          "niri/window" = {
            separate-outputs = true;
            icon = true;
            format = "{title}";
          };

          "niri/workspace-overview" = {
            separate-outputs = true;
            rewrite = {
              "org.telegram.desktop" = "telegram";
              "org.nicotine_plus.Nicotine" = "nicotine";
            };
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

          "custom/notif" = {
            tooltip = true;
            format = "{0} {icon}";
            format-icons = {
              notification = "󱅫";
              none = "󰂜";
              dnd-notification = "󰂠";
              dnd-none = "󰪓";
              inhibited-notification = "󰂛";
              inhibited-none = "󰪑";
              dnd-inhibited-notification = "󰂛";
              dnd-inhibited-none = "󰪑";
            };
            return-type = "json";
            exec-if = "which swaync-client";
            exec = "swaync-client -swb";
            on-click = "swaync-client -t -sw";
            on-click-right = "swaync-client -d -sw";
            escape = true;
          };
        };
      };
    };

    systemd.user.services = lib.mkMerge [
      (lib.listToAttrs (map
        (
          { name, path }: lib.nameValuePair "autostart-${name}" {
            Unit = {
              Description = "automatic starting ${name} on niri startup";
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
            };
            Install = { WantedBy = [ "graphical-session.target" ]; };
            Service = {
              ExecStart = path;
            };
          }
        )
        (defaultStartup ++ cfg.extraStartup))
      )
      {
        waybar.Service.Environment = [
          "PATH=${lib.makeBinPath (with pkgs; [
            i3-volume
            pavucontrol
            pulseaudio
            gawk
            swaynotificationcenter
            light
        ])}"
        ];
      }
    ];
  };
}
