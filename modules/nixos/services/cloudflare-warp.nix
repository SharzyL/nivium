{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.setup.services.cloudflare-warp;
in
{
  options.setup.services.cloudflare-warp = {
    enable = mkEnableOption "enable cloudflare-warp";
    package = mkPackageOption pkgs "cloudflare-warp" { };
    configFile = mkOption { type = types.str; };
  };

  config = mkIf cfg.enable {
    setup.systemd-hardening.cloudflare-warp = {
      enable = true;
      ambientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" "CAP_SYS_PTRACE" ];
      extraAF = [ "AF_NETLINK" ];
    };

    environment.systemPackages = [ cfg.package ];

    systemd.services.cloudflare-warp = {
      description = "Cloudflare warp daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [ pkgs.lsof pkgs.iproute2 ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/warp-svc";
        StateDirectory = [ "cloudflare-warp" ];
        RuntimeDirectory = [ "cloudflare-warp" ];
        LogsDirectory = [ "cloudflare-warp" ];
        Restart = "always";
      };
    };
  };
}

