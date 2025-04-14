{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.setup.services.sing-box-client;
in
{
  options.setup.services.sing-box-client = {
    enable = mkEnableOption "sing-box server";
    package = mkPackageOption pkgs "sing-box" { };
    configFile = mkOption { type = lib.types.path; default = "/var/lib/setup/sb.json"; };
  };

  config = mkIf cfg.enable {
    setup.systemd-hardening.sing-box = {
      enable = true;
      extraAF = [ "AF_NETLINK" ];
    };
    systemd.services.sing-box = {
      wantedBy = [ "multi-user.target" ];
      unitConfig.After = [ "network.target" "nss-lookup.target" ];

      serviceConfig = {
        ExecStartPre = [
          "${pkgs.coreutils}/bin/ln -sf ${pkgs.sing-geodb.ip} %S/sing-box/geosite.db"
          "${pkgs.coreutils}/bin/ln -sf ${pkgs.sing-geodb.site} %S/sing-box/geoip.db"
        ];
        ExecStart = "${cfg.package}/bin/sing-box -D %S/sing-box -c %d/config.json run";
        LimitNOFILE = "infinity";
        StateDirectory = "sing-box";
        LoadCredential = "config.json:${cfg.configFile}";
      };
    };
  };
}
