{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nivium.services.efb;
in
{
  options.nivium.services.efb = {
    package = mkPackageOption pkgs "efb" { };
    enable = mkEnableOption "efb wechat to telegram forwarder";
  };

  config = mkIf cfg.enable {
    nivium.systemd-hardening.efb = {
      enable = true;
    };

    systemd.services.efb = {
      description = "efb";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.ffmpeg ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/ehforwarderbot";
        StateDirectory = "efb";
        Restart = "on-failure";
        Environment = [
          "EFB_DATA_PATH=%S/efb"
        ];
      };
    };
  };
}

