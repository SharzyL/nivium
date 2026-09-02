{ config, ... }:

{
  imports = [
    ./services/atticd.nix
  ];

  sops.secrets."s1_helper_config" = { sopsFile = ../../secrets/jethro.yaml; };
  sops.secrets."rssbot_secret" = { sopsFile = ../../secrets/jethro.yaml; };
  sops.secrets."sb_secret" = { sopsFile = ../../secrets/jethro.yaml; };
  sops.secrets."chatgpt_bot" = { sopsFile = ../../secrets/jethro.yaml; };
  sops.secrets."syncplay_password" = { sopsFile = ../../secrets/jethro.yaml; };
  sops.secrets."rosetta_env" = { sopsFile = ../../secrets/jethro.yaml; };
  sops.secrets."cloudflared-creds" = { sopsFile = ../../secrets/jethro.yaml; };

  security.auditd.enable = true;

  nivium.services = {
    exporters = {
      enable = true;
      enableNode = true;
      enablePing = true;
    };

    derper = {
      enable = true;
      hostname = "jethro.d.shz.al";
      derpPort = 3043;
    };

    sing-box-server = {
      enable = true;
      host = "jethro.d.shz.al";
      clients = [
        { password = { _secret_from_env = "pwd1"; }; name = "u1"; }
        { password = { _secret_from_env = "pwd2"; }; name = "u2"; }
      ];
      envFile = config.sops.secrets."sb_secret".path;
    };

    rssbot = {
      enable = true;
      secretFile = config.sops.secrets."rssbot_secret".path;
    };

    nginx = {
      enable = true;
      sni-blocker.enable = true;
      wildcard-proxy = {
        enable = true;
        base-domain = "jethro.d.shz.al";
        proxies = {
          # syncplay handles SSL by itself, no need to proxy
          grafana.port = config.services.grafana.settings.server.http_port;
          attic = {
            port = 8533; # TODO: parse
            extraProxyConfig = ''
              client_max_body_size 2000M;
            '';
          };
        };
      };
    };

    acme-restart = {
      jethro-d-shz-al = {
        certNames = [ "jethro.d.shz.al" ];
        servicesToRestart = [ "sing-box.service" ];
      };
      syncplay-d-shz-al = {
        # syncplay's ssl update detection is based on mtime of cert file, thus not working
        certNames = [ config.nivium.services.nginx.wildcard-proxy.cert-name ];
        servicesToRestart = [ "syncplay.service" ];
      };
    };

    moltis.enable = true;
  };

  nivium.enableDNSACME = true;

  services.openssh.settings.X11Forwarding = true;

  # keep sshd from giving up with "Too many authentication failures" (and thereby
  # promoting every buffered publickey line into a fail2ban strike) when the
  # gpg agent offers more than the default 6 identities
  services.openssh.settings.MaxAuthTries = 20;

  services.tg-searcher = {
    enable = true;
    configFile = "%S/tg-searcher/config.yaml"; # require manually copy to host
  };

  services.green-rosetta = {
    enable = true;
    listen = "127.0.0.1:2445";
    configFile = ./green-rosetta.toml;
    envFile = config.sops.secrets."rosetta_env".path;
  };

  services.cloudflared = {
    enable = true;
    tunnels."967176fc-b025-4fcd-8f71-84957718a1b9" = {
      credentialsFile = config.sops.secrets."cloudflared-creds".path;
      ingress = {
        "rosetta.sharzy.in" = {
          service = "http://${config.services.green-rosetta.listen}";
        };
      };
      default = "http_status:404";
    };
  };

  services.fail2ban = {
    enable = true;

    # a single ssh connection can emit several failure lines (one per key the
    # agent offers), so the default of 3 is barely one fat-fingered attempt
    maxretry = 10;
    bantime = "10m";

    # gentle first ban, harsh on anyone who keeps knocking: 10m, 20m, 40m ... 48h
    bantime-increment = {
      enable = true;
      maxtime = "48h";
      overalljails = true;
    };

    # never ban ourselves over tailscale
    ignoreIP = [
      "100.64.0.0/10"
      "fd7a:115c:a1e0::/48"
    ];
  };

  # networking.firewall is off here, so the module's own partOf is empty; without
  # this an nftables reload (exporters.nix owns the ruleset, and flushRuleset is
  # on) wipes f2b-table while fail2ban still believes the bans are in place
  systemd.services.fail2ban.partOf = [ "nftables.service" ];

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3100;
        domain = "grafana.s.shz.al";
      };
      security.secret_key = "c317a3dbf8a15819eac20f1226b5bc2a920c6659a62f166d38b0a7acbeea531a";
    };
  };

  # handle prometheus
  services.prometheus = {
    enable = true;
    port = 9001;
    scrapeConfigs =
      let
        makeNodeScrape = name: addr: {
          job_name = name;
          static_configs = [{
            targets = [ addr ];
          }];
        };
      in
      [
        (makeNodeScrape "jethro" "jethro:9100")
        (makeNodeScrape "jethro.ping" "jethro:9102")

        (makeNodeScrape "akiko" "akiko:9100")
        (makeNodeScrape "akiko.smart" "akiko:9101")
        (makeNodeScrape "akiko.ping" "akiko:9102")

        (makeNodeScrape "sunra" "sunra:9100")
        (makeNodeScrape "sunra.ping" "sunra:9102")
      ];
  };

  services.syncplay = {
    # group = "nginx";
    enable = true;
    port = 8964;
    passwordFile = config.sops.secrets."syncplay_password".path;
    salt = "BUHV6TIUONBWIWKAWXN6OJZB";
    extraArgs = [ "--tls" "%d" ]; # since certDir is enforces to be a path
  };

  systemd.services.syncplay.serviceConfig =
    let
      name = config.nivium.services.nginx.wildcard-proxy.cert-name;
    in
    {
      LoadCredential = [
        "cert.pem:/var/lib/acme/${name}/cert.pem"
        "privkey.pem:/var/lib/acme/${name}/key.pem"
        "chain.pem:/var/lib/acme/${name}/chain.pem"
      ];
    };

  services.tailscale = {
    enable = true;
  };
}
