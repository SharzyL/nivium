{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nivium.services.flood;
in
{
  options.nivium.services.flood = {
    enable = mkEnableOption "enable flood";
    package = mkPackageOption pkgs "flood" { };
    baseuri = mkOption { type = types.nullOr types.str; default = null; };
    port = mkOption { type = types.port; default = 3000; };
  };

  config = mkIf cfg.enable {
    nivium.systemd-hardening.flood = {
      enable = true;
      onlyLocalNetwork = true;
      memoryDenyWriteExecute = false; # node has some magic
      systemCallFilter = [ "@system-service" "~@privileged" "~@resources" "@pkey" ];
    };

    systemd.services.flood = {
      description = "modern web UI for torrent";
      after = [ "network.target" "transmission.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.mediainfo ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/flood --port ${toString cfg.port} --rundir %S/flood"
          + optionalString (cfg.baseuri != null) " -baseurl ${cfg.baseuri}";
        StateDirectory = "flood";
        Environment = [ "HOME=%S/flood" ]; # let uv_os_homedir happy with PrivateUsers
      };
    };
  };
}

