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
        user = user;
        command = pkgs.writeShellScript "niri-start" ''
          niri-session
        '';
      };
    };

    environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json".text = ''
      {
        "rules": [
        {
          "pattern": {
            "feature": "procname",
              "matches": "niri"
          },
            "profile": "Limit Free Buffer Pool On Wayland Compositors"
        }
        ],
        "profiles": [
        {
          "name": "Limit Free Buffer Pool On Wayland Compositors",
          "settings": [
          {
            "key": "GLVidHeapReuseRatio",
            "value": 0
          }
          ]
        }
        ]
      }
    '';

    systemd.services.greetd.serviceConfig.ExecStop = "${pkgs.procps}/bin/pkill -u ${user} niri";
  };
}
