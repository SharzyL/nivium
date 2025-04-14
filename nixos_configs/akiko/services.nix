{ config, pkgs, lib, ... }:

{
  imports = [
    ./services/jellyfin.nix
  ];

  sops.secrets."thu_passwd" = { sopsFile = ../../secrets/desktop.yaml; };
  sops.secrets."goauthing_config" = { sopsFile = ../../secrets/desktop.yaml; };
  sops.secrets."restic_env" = { owner = "sharzy"; sopsFile = ../../secrets/desktop.yaml; };
  sops.secrets."oomori_rsync_env" = { sopsFile = ../../secrets/desktop.yaml; };

  setup.services = {
    goauthing = {
      enable = true;
      configFile = config.sops.secrets."goauthing_config".path;
    };
    ddns = {
      enable = true;
      configFile = "/var/lib/setup/ddns.json";
    };
    flood.enable = true;
    sing-box-client.enable = true;
    mihomo.enable = true;
    cloudflare-warp.enable = false;  # it somehow breaks dns
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
          flood.port = config.setup.services.flood.port;
          qb = {
            port = config.setup.services.qbittorrent.webui-port;
            extraProxyConfig = ''
              proxy_cookie_path  /  "/; Secure";
            '';
          };
        };
      };
    };
  };
  setup.enableDNSACME = true;

  users.users."sharzy".extraGroups = lib.mkBefore [ "qbittorrent" ];

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

  services.openvpn.servers = {
    felix = { config = '' config /var/lib/setup/felix.ovpn ''; };
  };
  systemd.services.openvpn-felix.unitConfig = {
    After = lib.mkForce [ "network-online.target" ];
    Wants = lib.mkForce [ "network-online.target" ];
  };

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
}
