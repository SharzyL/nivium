{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nivium.services.moltis;
  user = "moltis";
  group = "moltis";
  serviceName = "moltis";
in
{
  options.nivium.services.moltis = {
    package = mkPackageOption pkgs "moltis" { };
    enable = mkEnableOption "moltis service";
  };

  config = mkIf cfg.enable {
    nivium.systemd-hardening.${serviceName} = {
      enable = true;
      dynamicUser = false;
      extraAF = [ "AF_NETLINK" ];
    };

    users.users.${user} = {
      group = group;
      isNormalUser = true;
      description = "moltis user";
      home = "/var/lib/${serviceName}";
    };

    users.groups.${group} = { };

    systemd.services.${user} = {
      description = "moltis gateway";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.gh ];
      serviceConfig = {
        User = user;
        Group = group;
        ExecStart = "${cfg.package}/bin/moltis";
        Restart = "on-failure";

        StateDirectory = serviceName;
        StateDirectoryMode = "0750";
        Environment = [
          "MOLTIS_SHARE_DIR=${cfg.package}/share"
          "MOLTIS_DATA_DIR=%S/${serviceName}/data"
          "MOLTIS_CONFIG_DIR=%S/${serviceName}/config"
          "PATH=/run/current-system/sw/bin/"
        ];
      };
    };
  };
}

