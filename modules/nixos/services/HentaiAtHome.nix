{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nivium.services.HentaiAtHome;
in
{
  options.nivium.services.HentaiAtHome = {
    enable = mkEnableOption "enable HentaiAtHome";
    port = mkOption { type = lib.types.port; };
    package = mkPackageOption pkgs "HentaiAtHome" { };
    clientLogin = mkOption { type = lib.types.path; description = "a $clientID-$clientKey format file"; };
  };

  config = mkIf cfg.enable {
    nivium.systemd-hardening.HentaiAtHome = {
      enable = true;
      memoryDenyWriteExecute = false;
    };

    systemd.services.HentaiAtHome = {
      description = "HentaiAtHome service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStartPre = [
          "${pkgs.writeShellScript "create-login" ''
            mkdir -p $STATE_DIRECTORY/hath/data
            rm -f $STATE_DIRECTORY/hath/data/client_login
            ln -s $CREDENTIALS_DIRECTORY/client_login $STATE_DIRECTORY/hath/data/client_login
          ''}"
        ];
        ExecStart =
          let
            dirArgs = "--cache-dir=%C/hath --data-dir=%S/hath/data --download-dir=%S/hath/download --log-dir=%L/hath";
          in
          "${cfg.package}/bin/HentaiAtHome ${dirArgs} --port ${toString cfg.port}";
        StateDirectory = "hath";
        CacheDirectory = "hath";
        LogsDirectory = "hath";
        LoadCredential = "client_login:${cfg.clientLogin}";
      };
    };
  };
}
