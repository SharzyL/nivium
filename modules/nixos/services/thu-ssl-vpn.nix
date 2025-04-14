{ config, lib, ... }:

with lib;
let
  cfg = config.nivium.services.thu-ssl-vpn;
in
{
  options.nivium.services.thu-ssl-vpn = with lib.types; {
    enable = mkEnableOption "thu ssl vpn";
    username = mkOption { type = str; };

    password = mkOption { type = nullOr str; default = null; };
    passwordFile = mkOption { type = nullOr str; default = null; };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.passwordFile == null) != (cfg.password == null);
        message = "Either but not both `passwordFile` and `password` should be specified for thu-ssl-vpn";
      }
    ];

    networking.openconnect.interfaces."thu-vpn" = {
      gateway = "https://sslvpn.tsinghua.edu.cn";
      passwordFile =
        if cfg.passwordFile != null
        then cfg.passwordFile
        else builtins.toFile "thu-vpn-passwd" cfg.password;

      user = cfg.username;
      protocol = "pulse";
    };

    systemd.services.openconnect-thu-vpn.serviceConfig.Restart = "on-failure";
  };
}
