{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nivium.graphics.niri;
  user = config.nivium.graphics.user;
in
{
  options.nivium.graphics.niri = {
    enable = mkEnableOption "niri base config";
  };

  config = mkIf cfg.enable {
    programs.niri = {
      enable = true;
      useNautilus = true;
    };

    security.pam.services.swaylock.u2fAuth = true;

    services.dbus.implementation = "broker";

    services.greetd = {
      enable = true;
      settings.default_session = {
        user = config.nivium.graphics.user;
        command = pkgs.writeShellScript "niri-start" ''
          export $(${pkgs.systemd}/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
          pkill -u "${user}" waybar
          pkill -u "${user}" fcitx5
          if [ -r /home/${user}/.local/state/nix/profile/etc/profile.d/hm-session-vars.sh ]; then
            . /home/${user}/.local/state/nix/profile/etc/profile.d/hm-session-vars.sh
          fi
          ${pkgs.light}/bin/light -I
          exec niri-session
        '';
      };
    };
  };
}
