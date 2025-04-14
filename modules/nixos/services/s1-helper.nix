{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.setup.services.s1-helper;
in
{
  options.setup.services.s1-helper = {
    enable = mkEnableOption "s1 bot";
    package = mkPackageOption pkgs "s1-helper" { };
    configFile = mkOption { type = with types; nullOr str; };
  };

  config = mkIf cfg.enable {
    setup.systemd-hardening.s1-helper.enable = true;
    systemd.services.s1-helper = {
      description = "s1 bot";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/s1-helper %d/config.json";
        Restart = "on-failure";
        LoadCredential = "config.json:${cfg.configFile}";
      };
    };
  };
}
