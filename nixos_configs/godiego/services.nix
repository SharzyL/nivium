{ config, lib, ... }:

{
  sops.secrets."thu_passwd" = { sopsFile = ../../secrets/desktop.yaml; };
  sops.secrets."goauthing_config" = { sopsFile = ../../secrets/desktop.yaml; };

  nivium.services = {
    goauthing = {
      enable = true;
      configFile = config.sops.secrets."goauthing_config".path;
    };
    sing-box-client.enable = true;
    mihomo.enable = true;
    ddns = {
      enable = true;
      configFile = "/var/lib/nivium/ddns.json";
    };
    cloudflare-warp = {
      enable = true;
    };
  };
  nivium.enableDNSACME = true;

  # services.openvpn.servers = {
  #   felix = { config = '' config /var/lib/nivium/felix.ovpn ''; };
  # };

  services.smartdns = {
    enable = true;
    settings = {
      log-level = "debug";
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
