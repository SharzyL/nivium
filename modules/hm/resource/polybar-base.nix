options:

let
  colors = {
    background = "#282A2E";
    background-alt = "#373B41";
    foreground = "#C5C8C6";
    primary = "#F0C674";
    secondary = "#8ABEB7";
    negative = "#f0932b";
    safe = "#27ae60";
    alert = "#A54242";
    disabled = "#707880";
  };
in
{
  "bar/default" = {
    height = "${toString options.heightPt}pt";
    bottom = true;
    inherit (colors) background foreground;
    border-color = "#00000000";
    font-0 = "monospace:size=${toString options.fontSize};2";
    font-1 = "Noto Sans CJK SC:size=${toString options.fontSize};2";
    font-2 = "Noto Color Emoji:scale=${toString options.emojiScale}";
    separator = "|";
    separator-foreground = colors.disabled;
    line-size = 3;

    module-margin = 1;
    modules-left = [ "xworkspaces" "xwindow" ];
    modules-right = [ "battery" "backlight" "pulseaudio" "trackpad-power" "wlan" "eth" "filesystem" "memory" "cpu" "date" "tray" ];

    enable-ipc = true;
  };

  "module/xworkspaces" = {
    type = "internal/xworkspaces";
    pin-workspaces = "true";

    label-active = "%name%";
    label-active-background = colors.background-alt;
    label-active-underline = colors.primary;
    label-active-padding = "1";

    label-occupied = "%name%";
    label-occupied-padding = "1";

    label-urgent = "%name%";
    label-urgent-background = colors.alert;
    label-urgent-padding = "1";

    label-empty = "%name%";
    label-empty-foreground = colors.disabled;
    label-empty-padding = "1";
  };

  "module/xwindow" = {
    type = "internal/xwindow";
    label = "%title:0:60:...%";
  };

  "module/filesystem" = {
    type = "internal/fs";
    interval = "25";

    mount-0 = "/";

    label-mounted = "%{F#F0C674}'%mountpoint%'%{F-} %used%";

    label-unmounted = "%mountpoint% not mounted";
    label-unmounted-foreground = colors.disabled;
  };

  "module/pulseaudio" = {
    type = "internal/pulseaudio";

    format-volume-prefix = "VOL ";
    format-volume = "<label-volume>";
    format-volume-underline = colors.secondary;
    label-volume = "%percentage%%";

    label-muted = "muted";
    label-muted-foreground = colors.disabled;

    click-right = "pavucontrol";
  };

  "module/memory" = {
    type = "internal/memory";
    interval = "2";
    format-prefix = "RAM ";
    warn-percentage = 90;
    format-underline = colors.secondary;
    format-warn-underline = colors.alert;
    label = "%percentage_used:2%%";
  };

  "module/cpu" = {
    type = "internal/cpu";
    interval = "2";
    format-prefix = "CPU ";
    warn-percentage = 60;
    format-underline = colors.secondary;
    format-warn-underline = colors.alert;
    label = "%percentage:2%%";
  };

  "network-base" = {
    type = "internal/network";
    interval = "2";
    format-connected = "<label-connected>";
    format-disconnected = "<label-disconnected>";
    label-disconnected = "%{F#F0C674}%ifname%%{F#707880} disconnected";
  };

  "module/wlan" = {
    "inherit" = "network-base";
    interface-type = "wireless";
    label-connected = "%{F#F0C674}%ifname%%{F-} %essid% %local_ip% %{F#F0C674}↑%{F-} %upspeed% %{F#F0C674}↓%{F-} %downspeed%";
  };

  "module/eth" = {
    "inherit" = "network-base";
    interface-type = "wired";
    label-connected = "%{F#F0C674}%ifname%%{F-} %local_ip% %{F#F0C674}↑%{F-} %upspeed% %{F#F0C674}↓%{F-} %downspeed%";
  };

  "module/date" = {
    type = "internal/date";
    interval = "1";

    date = "%Y-%m-%d %a %H:%M:%S";

    label = "%date%";
    label-foreground = colors.primary;
  };

  "module/battery" = {
    type = "internal/battery";
    label-charging = "Bat(c) %percentage_raw%%";
    label-full = "Bat(f) %percentage_raw%%";
    label-low = "Bat(!) %percentage_raw%%";
    format-charging-underline = colors.safe;

    label-discharging = "Bat(d) %percentage_raw%%";
    format-discharging-underline = colors.secondary;

    low-at = 20;
    format-low-underline = colors.alert;

    full-at = 100;
    format-full-underline = colors.safe;
  };

  "module/backlight" = {
    type = "internal/backlight";
    enable-scroll = "true";
    card = "intel_backlight";
    format-prefix = "Li ";
    format-underline = colors.secondary;
  };

  "module/tray" = {
    type = "internal/tray";
    tray-spacing = "8px";
  };



  "settings" = {
    screenchange-reload = "true";
    pseudo-transparency = "true";
  };
}
