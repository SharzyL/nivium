{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./services/jellyfin.nix
    inputs.hermes-agent.nixosModules.default
  ];

  sops.secrets."thu_passwd" = { sopsFile = ../../secrets/desktop.yaml; };
  sops.secrets."goauthing_config" = { sopsFile = ../../secrets/desktop.yaml; };
  sops.secrets."restic_env" = { owner = "sharzy"; sopsFile = ../../secrets/desktop.yaml; };
  sops.secrets."oomori_rsync_env" = { sopsFile = ../../secrets/desktop.yaml; };
  sops.secrets."cloudflared-creds" = { sopsFile = ../../secrets/akiko.yaml; };
  # holds the [client] section of the rathole config, i.e. default_token
  sops.secrets."rathole_token" = { sopsFile = ../../secrets/akiko.yaml; };
  # dotenv-style KEY=VALUE lines for hermes-agent, see services.hermes-agent below
  sops.secrets."hermes_env" = { sopsFile = ../../secrets/akiko.yaml; };

  nivium.services = {
    goauthing = {
      enable = true;
      configFile = config.sops.secrets."goauthing_config".path;
    };
    ddns = {
      enable = true;
      configFile = "/var/lib/nivium/ddns.json";
    };
    flood.enable = true;
    # sing-box-client.enable = true;
    mihomo.enable = true;
    cloudflare-warp.enable = false; # it somehow breaks dns
    exporters = {
      enable = true;
      enableNode = true;
      enableSmart = true;
      enablePing = true;
    };
    qbittorrent = {
      enable = true;
      download-dir = "/tank/akiko_torrents";
    };
    nginx = {
      enable = true;
      sni-blocker = {
        enable = true;
        port = 2443;
      };
      wildcard-proxy = {
        enable = true;
        port = 2443;
        base-domain = "akiko.d.shz.al";
        proxies = {
          flood.port = config.nivium.services.flood.port;
          qb = {
            port = config.nivium.services.qbittorrent.webui-port;
            extraProxyConfig = ''
              proxy_cookie_path  /  "/; Secure";
            '';
          };
        };
      };
    };
  };
  nivium.enableDNSACME = true;

  # publish our sshd on sunra:23333
  services.rathole = {
    enable = true;
    role = "client";
    credentialsFile = config.sops.secrets."rathole_token".path;
    settings.client = {
      remote_addr = "sunra.d.shz.al:24333";
      services.akiko_ssh.local_addr = "127.0.0.1:23333";
    };
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    # expects DEEPSEEK_API_KEY, OHMYGPT_API_KEY, DISCORD_BOT_TOKEN, DISCORD_ALLOWED_USERS
    environmentFiles = [ config.sops.secrets."hermes_env".path ];
    environment = {
      DISCORD_HOME_CHANNEL = "1557648855615672330";
    };
    settings = {
      model = {
        provider = "deepseek";
        default = "deepseek-flash";
      };
      # switch with `/model custom:ohmygpt:<model>`
      providers.ohmygpt = {
        api = "https://api.ohmygpt.com/v1";
        key_env = "OHMYGPT_API_KEY";
        transport = "chat_completions";
        discover_models = false;
        models = [
          "gemini-3.8-flash"
          "gemini-3.5-flash-lite"
          "gemini-3.1-pro-preview"
          "grok-4.5"
          "glm-5.2"
        ];
      };
      discord = {
        require_mention = true;
        auto_thread = true;
        reactions = true;
      };
      group_sessions_per_user = true;
    };
  };
  systemd.services.hermes-agent.environment = {
    HTTPS_PROXY = "http://127.0.0.1:1094";
    HTTP_PROXY = "http://127.0.0.1:1094";
  };

  users.users."sharzy".extraGroups = lib.mkBefore [ "qbittorrent" ];
  systemd.services.ddns.serviceConfig.Environment = [
    "HTTPS_PROXY=http://127.0.0.1:1094"
  ];

  # restic
  systemd.services.auto-restic = {
    description = "automatic sync restic";
    after = [ "network.target" ];
    serviceConfig =
      let
        dir = "ws";
      in
      {
        Type = "oneshot";
        ExecStart = "${pkgs.restic}/bin/restic backup ${dir} --exclude-file=${dir}/.restic-exclude";
        EnvironmentFile = config.sops.secrets."restic_env".path;
        WorkingDirectory = "~";
        User = "sharzy";
      };
  };

  systemd.timers.auto-restic = {
    timerConfig.OnCalendar = "00,06,12,18:00";
    wantedBy = [ "timers.target" ];
  };

  # restic
  systemd.services.mus-sync = {
    description = "automatic rsync /tank/mus";
    after = [ "network.target" ];
    path = with pkgs; [ rsync ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "mus-sync" ''
        rsync -aP --delete bandcamp cd others pt pt.old slsk web --exclude .src --exclude '*.torrent' rsync://sharzy@oomori.d.shz.al/mus
      '';
      Environment = [ "RSYNC_PROXY=localhost:1094" ];
      EnvironmentFile = config.sops.secrets."oomori_rsync_env".path;
      WorkingDirectory = "/tank/mus";
    };
  };
  systemd.timers.mus-sync = {
    timerConfig.OnCalendar = "*:0/15";
    wantedBy = [ "timers.target" ];
  };

  # services.openvpn.servers = {
  #   felix = { config = '' config /var/lib/nivium/felix.ovpn ''; };
  # };
  # systemd.services.openvpn-felix.unitConfig = {
  #   After = lib.mkForce [ "network-online.target" ];
  #   Wants = lib.mkForce [ "network-online.target" ];
  # };

  services.smartdns = {
    enable = true;
    settings = {
      server = [
        "8.8.8.8"
        "1.1.1.1"
        "119.29.29.29"
        "114.114.114.114"
        "101.6.6.6" # tuna v4
        "2001:da8::666" # tuna v6
        "2402:4e00::" # dnspod v6

        "100.100.100.100 -group ts -exclude-default-group"
      ];
      server-tls = [
        "8.8.8.8:853"
        "1.1.1.1:853"
        "1.12.12.12" # dnspod doh
      ];
      server-https = [
        "https://cloudflare-dns.com/dns-query"
        "https://doh.pub/dns-query"
      ];
      prefetch-domain = true;
      nameserver = [
        "/hydra-bushi.ts.net/ts"
      ];
    };
  };

  services.resolved.enable = false;
  networking = {
    nameservers = lib.mkBefore [ "127.0.0.1" ];
    search = [ "hydra-bushi.ts.net" ];
  };

  services.tailscale = {
    enable = true;
  };

  services.upower.enable = true;

  services.cloudflared = {
    enable = true;
    tunnels."33d869ff-6935-40fa-9982-7a770578cefe" = {
      credentialsFile = config.sops.secrets."cloudflared-creds".path;
      default = "http_status:404";
    };
  };
}
