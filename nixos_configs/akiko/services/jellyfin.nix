{ ... }:

{
  services.jellyfin = {
    enable = true;
    user = "sharzy";
  };

  setup.services.nginx.wildcard-proxy.proxies.jellyfin = { };

  services.nginx.virtualHosts = {
    "jellyfin.akiko.d.shz.al".locations =
      let
        jhost = "127.0.0.1:8096";
      in
      {
        "= /" = {
          return = "302 https://$host:2443/web/";
        };
        "/" = {
          proxyPass = "http://${jhost}";
          recommendedProxySettings = true;
          extraConfig = ''
            proxy_buffering off;
          '';
        };
        "= /web/" = {
          proxyPass = "http://${jhost}/web/index.html";
          recommendedProxySettings = true;
        };
        "/socket" = {
          proxyPass = "http://${jhost}";
          recommendedProxySettings = true;
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };
      };
  };

  systemd.services.jellyfin.serviceConfig.Environment = let proxyUri = "http://127.0.0.1:1094"; in [
    "all_proxy=${proxyUri}"
    "HTTPS_PROXY=${proxyUri}"
    "HTTP_PROXY=${proxyUri}"
    "https_proxy=${proxyUri}"
    "http_proxy=${proxyUri}"
  ];
}
