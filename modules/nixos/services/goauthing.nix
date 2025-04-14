{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nivium.services.goauthing;
  bin = "${cfg.package}/bin/auth-thu";
in
{
  options.nivium.services.goauthing = {
    package = mkPackageOption pkgs "goauthing" { };
    enable = mkEnableOption "goauthing service";
    configFile = mkOption { type = types.nullOr types.str; };
  };

  config = mkIf cfg.enable {
    nivium.systemd-hardening.goauthing = {
      enable = true;
      systemCallFilter = [ "@system-service" "~@privileged" ];
    };

    systemd.services.goauthing = {
      description = "tsinghua networking auth tool";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        ExecStartPre = [
          "-${bin} -c %d/config.json -D deauth"
          "-${bin} -c %d/config.json -D auth"
          "-${bin} -c %d/config.json -D login"
        ];
        ExecStart = "${bin} -c %d/config.json -D online";
        Restart = "always";
        RestartSec = 5;
        LoadCredential = "config.json:${cfg.configFile}";
      };
    };
  };
}
