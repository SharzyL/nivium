{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.setup.graphics.sway;
  user = config.setup.graphics.user;
in
{
  options.setup.graphics.sway = {
    enable = mkEnableOption "sway base config";
  };

  config = mkIf cfg.enable {
    security.polkit.enable = true;
    security.pam.services.swaylock = { };
    security.rtkit.enable = true;

    # services.gnome.at-spi2-core.enable = true;  # to remove warning of xdg-desktop-portal-gtk
    programs.light.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    services.dbus.enable = true;

    xdg.portal = {
      wlr.enable = true;
    };

    users.users.${user}.extraGroups = lib.mkBefore [
      "video" "audio"
    ];

    services.greetd = {
      enable = true;
      settings.default_session = {
        user = config.setup.graphics.user;
        command = pkgs.writeShellScript "sway" ''
          export $(${pkgs.systemd}/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
          ${pkgs.findutils}/bin/find /run/user/$(id -u) -maxdepth 1 -name "sway-ipc.$(id -u).*.sock" -delete
          pkill -u "${user}" waybar
          pkill -u "${user}" fcitx5
          ${pkgs.light}/bin/light -I
          exec sway
        '';
      };
    };
    systemd.services.greetd = {
      serviceConfig = {
        # TODO:
        ExecStop = [
          # "${pkgs.findutils}/bin/find /run/user/%U -maxdepth 1 -name sway-ipc.%U.*.sock -delete"
        ];
      };
    };
  };
}
