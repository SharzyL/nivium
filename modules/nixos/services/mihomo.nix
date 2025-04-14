{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.setup.services.mihomo;
in
{
  options.setup.services.mihomo = {
    enable = mkEnableOption "mihomo server";
    package = mkPackageOption pkgs "clash-meta" { };
    configFile = mkOption { type = lib.types.path; default = "/var/lib/setup/mihomo.yaml"; };
  };

  config = mkIf cfg.enable {
    setup.systemd-hardening.mihomo = {
      enable = true;
      extraAF = [ "AF_NETLINK" ];
      systemCallFilter = [ "@system-service" "~@resources" "~@privileged" "bpf" ];
    };
    systemd.services.mihomo = {
      wantedBy = [ "multi-user.target" ];
      unitConfig.After = [ "network.target" "nss-lookup.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/clash-meta -d %S/mihomo -f %d/config.yaml run";
        LimitNOFILE = "infinity";
        StateDirectory = "mihomo";
        LoadCredential = "config.yaml:${cfg.configFile}";
        ExecReload = "/bin/kill -HUP $MAINPID";
      };
    };
  };
}
