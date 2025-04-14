{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.setup.services.ddns;
in
{
  options.setup.services.ddns = {
    enable = mkEnableOption "enable ddns";
    package = mkPackageOption pkgs "python-ddns" { };
    configFile = mkOption { type = types.str; };  # TODO: generate it
    onCalendar = mkOption { type = types.str; default = "*:0/3"; };
  };

  config = mkIf cfg.enable {
    setup.systemd-hardening.ddns = {
      enable = true;
    };

    systemd.services.ddns = {
      description = "ddns daemon";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        LoadCredential = [ "config.json:${cfg.configFile}" ];
        ExecStart = "${cfg.package}/bin/ddns -c %d/config.json";
        CacheDirectory = "ddns";
        Environment = [
          "TMPDIR=%S/ddns"
        ];
      };
    };
    systemd.timers.ddns = {
      timerConfig.OnCalendar = cfg.onCalendar;
      wantedBy = [ "timers.target" ];
    };
  };
}

