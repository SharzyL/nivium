{ config, lib, ... }:

let
  cfg = config.setup.services.nginx;
in
{
  options.setup.services.nginx = {
    enable = lib.mkEnableOption "enable nginx service";

    sni-blocker = {
      enable = lib.mkEnableOption "enable nginx-sni-blocker";
      port = lib.mkOption { type = lib.types.port; default = 443; };
    };

    wildcard-proxy = {
      enable = lib.mkEnableOption "enable wildcard-proxy";
      base-domain = lib.mkOption { type = lib.types.str; };
      port = lib.mkOption { type = lib.types.port; default = 443; };

      cert-name = lib.mkOption { type = lib.types.str; readOnly = true; };

      proxies = with lib; mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            port = mkOption { type = types.nullOr types.port; default = null; };
            extraProxyConfig = mkOption { type = types.str; default = ""; };
          };
        });
        default = { };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.nginx.enable = true;
      services.nginx.enableReload = true;
    })

    (lib.mkIf cfg.sni-blocker.enable {
      services.nginx.virtualHosts."_sni_blocker" = {
        serverName = "_";
        listen = [
          { addr = "[::]"; port = cfg.sni-blocker.port; ssl = true; }
          { addr = "0.0.0.0"; port = cfg.sni-blocker.port; ssl = true; }
        ];
        extraConfig = ''
          ssl_reject_handshake on;
        '';
      };
    })

    (lib.mkIf cfg.wildcard-proxy.enable (
      let
        wpCfg = cfg.wildcard-proxy;
        wpCertName = "wildcard.${cfg.wildcard-proxy.base-domain}";
      in
      {
        security.acme.certs.${wpCertName} = {
          domain = "*.${wpCfg.base-domain}";
          group = "nginx";
        };

        setup.services.nginx.wildcard-proxy.cert-name = wpCertName;

        services.nginx.virtualHosts = lib.mapAttrs'
          (name: pcfg: lib.nameValuePair "${name}.${wpCfg.base-domain}" {
            addSSL = true;
            useACMEHost = wpCertName;
            listen = [
              { addr = "[::]"; port = wpCfg.port; ssl = true; }
              { addr = "0.0.0.0"; port = wpCfg.port; ssl = true; }
            ];
            locations."/" = lib.mkIf (pcfg.port != null) {
              recommendedProxySettings = true;
              proxyPass = "http://localhost:${toString pcfg.port}";
              extraConfig = pcfg.extraProxyConfig;
            };
          })
          wpCfg.proxies;
      }
    ))
  ];
}
