{ config, pkgs, ... }:

{
  sops.secrets."attic_secret" = {
    sopsFile = ../../../secrets/jethro.yaml;
  };

  services.postgresql = {
    enable = true;
    settings.port = 5432;
    package = pkgs.postgresql_16;
    ensureDatabases = [ "atticd" ];
    ensureUsers = [{
      name = "atticd";
      ensureDBOwnership = true;
    }];
  };

  services.atticd = {
    enable = true;
    environmentFile = config.sops.secrets."attic_secret".path;
    settings = {
      listen = "127.0.0.1:8533";
      database.url = "postgresql:///atticd?host=/run/postgresql";
      allowed-hosts = [ "attic.jethro.d.shz.al" ];
      api-endpoint = "https://attic.jethro.d.shz.al/";
      chunking = {
        nar-size-threshold = 128 * 1024;
        min-size = 64 * 1024;
        avg-size = 128 * 1024;
        max-size = 2048 * 1024;
      };
      storage = {
        type = "s3";
        bucket = "attic";
        region = "us-east-1"; # is it used?
        endpoint = "https://1ddaf86dbca12e8f4fcaa76f32bb707d.r2.cloudflarestorage.com";
      };
    };
  };

  sops.secrets.attic_nginx_proxy_config = {
    sopsFile = ../../../secrets/jethro.yaml;
    owner = "nginx";
  };
  services.nginx.virtualHosts."cache.shz.al" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://" + config.services.atticd.settings.listen;
      extraConfig = ''
        client_max_body_size 2000M;
        include ${config.sops.secrets.attic_nginx_proxy_config.path};
        proxy_set_header Host "attic.jethro.d.shz.al";
      '';
    };
  };
}
