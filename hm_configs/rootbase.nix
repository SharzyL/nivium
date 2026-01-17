{ ... }:

{
  home.username = "root";
  home.homeDirectory = "/root";
  nivium.profile = "full";

  # container-specific config
  # may requires DBUS_SESSION_BUS_ADDRESS=/dev/null
  targets.genericLinux.enable = true;
  systemd.user.startServices = false;
}
