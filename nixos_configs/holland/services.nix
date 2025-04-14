{ config, ... }:

{
  setup = {
    services = {
      exporters = {
        enable = true;
        enableNode = true;
        enablePing = true;
      };
      flood = {
        enable = true;
        baseuri = "/_flood";
      };
      nginx.enable = true;
    };
    enableDNSACME = true;
  };

  services.samba = {
    enable = true;
    settings = {
      store = {
        path = "/store";
        comment = "store";
        public = "no";
        writable = "yes";
        "force user" = "sharzy";
      };
      global = {
        security = "user";
        "workgroup" = "SHZAL";
        "hosts allow" = "2001:470:fceb::/48 192.168. 2a0c:b641:69c:900::/56";
        "server string" = "holland-samba";
      };
    };
  };

  services.transmission = {
    enable = true;
    user = "sharzy";
    openRPCPort = true;
    settings = {
      rpc-port = 9091;
      download-dir = "/store/torrent";
      incomplete-dir = "/store/torrent/.imcomplete";
    };
  };
  systemd.services.transmission = {
    serviceConfig = {
      Restart = "on-failure";
      MemoryMax = "1.5G";
      CPUQuota = "60%";
    };
  };

  sops = {
    secrets = {
      http_username = { sopsFile = ../../secrets/holland.yaml; };
      http_passwd = { sopsFile = ../../secrets/holland.yaml; };
    };
    templates = {
      "nginx_htpasswd" = {
        owner = "nginx";
        content = with config.sops.placeholder; "${http_username}:${http_passwd}";
      };
      "webdav_env".content = with config.sops.placeholder; ''
        WEBDAV_USERNAME=${http_username}
        WEBDAV_PASSWORD={bcrypt}${http_passwd}
      '';
    };
  };

  services.nginx = {
    commonHttpConfig = ''
      map $upstream_http_content_type $return_content_type {
        application/json text/html;
        * $upstream_http_content_type;
      }
    '';
    virtualHosts = {
      "wd.holland.d.shz.al" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://[::1]:11452/";
          recommendedProxySettings = true;
        };
      };
      "holland.d.shz.al" = {
        enableACME = true;
        forceSSL = true;
        locations."^~ /_flood/" = {
          proxyPass = "http://localhost:3000/";
        };
        locations."/_public/" = {
          alias = "/store/public/";
        };
        locations."/" = {
          proxyPass = "http://[::1]:11451/";
          extraConfig = ''
            proxy_hide_header Content-Type;
            add_header Content-Type $return_content_type;
          '';
          basicAuthFile = config.sops.templates."nginx_htpasswd".path;
        };
      };

      "localhost" = {
        listen = [{ addr = "[::1]"; port = 11451; }];
        default = true;
        serverName = "_";
        locations."/" = {
          root = "/store";
          extraConfig = ''
            autoindex on;
            autoindex_format json;

            addition_types application/json;
            add_before_body /.theme/header.html;
            add_after_body /.theme/footer.html;
          '';
        };
      };
    };
  };

  services.webdav = {
    enable = true;
    user = "sharzy";
    group = "users";
    settings = {
      address = "[::1]";
      port = 11452;
      directory = "/store";
      permissions = "CRUD";
      behindProxy = true;
      users = [
        { username = "{env}WEBDAV_USERNAME"; password = "{env}WEBDAV_PASSWORD"; }
      ];
    };
  };
  systemd.services.webdav.serviceConfig.EnvironmentFile = [ config.sops.templates."webdav_env".path ];

  services.tailscale.enable = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
  };
}
