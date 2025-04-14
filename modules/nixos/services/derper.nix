{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nivium.services.derper;
  derpHttpsPort = 3044;
in
{
  options.nivium.services.derper = with lib.types; {
    package = mkPackageOption pkgs "derper" { };
    enable = mkEnableOption "derper";
    hostname = mkOption { type = str; };
    derpPort = mkOption { type = port; default = 443; };
    httpsPort = mkOption { type = port; default = 3044; };
  };

  config = mkIf cfg.enable {
    boot.kernel.sysctl = lib.mkDefault {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    nivium.systemd-hardening.derper = {
      enable = true;

      # derper uses `setrlimit` in @resources group
      systemCallFilter = [ "@system-service" "~@privileged" ];
    };

    systemd.services.derper = {
      description = "derper server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.derper}/bin/derper -hostname=${cfg.hostname} -verify-clients "
          + "-a :${toString cfg.httpsPort} -c %S/derper/derper.key";
        DynamicUser = true;
        StateDirectory = "derper";
        Restart = "on-failure";
      };
    };

    security.acme.certs.${cfg.hostname} = { };
    users.users.nginx.extraGroups = [ "acme" ];

    services.nginx = {
      enable = true;

      virtualHosts.${cfg.hostname} = {
        useACMEHost = cfg.hostname;
        addSSL = true;
        listen = [
          { addr = "0.0.0.0"; port = cfg.derpPort; ssl = true; }
        ];
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString derpHttpsPort}";
          recommendedProxySettings = true;
          extraConfig = ''
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };
      };
    };
  };
}
