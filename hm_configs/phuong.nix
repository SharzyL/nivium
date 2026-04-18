{ pkgs, ... }:

{
  home.username = "root";
  home.homeDirectory = "/root";
  nivium.profile = "minimal";

  # container-specific config
  # may requires DBUS_SESSION_BUS_ADDRESS=/dev/null
  targets.genericLinux.enable = false;
  systemd.user.startServices = false;

  home.packages = with pkgs; [
    sing-box
    chatgpt-telegram-bot
  ];
}
