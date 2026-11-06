{ config, pkgs, lib, ... }:

# the `nivium.*` options and the config each toggle turns on

with lib;
let
  cfg = config.nivium;
in
{
  options.nivium = {
    adminUser = mkOption {
      type = types.str;
      default = "sharzy";
    };
    behindGFW = mkOption {
      type = types.bool;
      default = false;
    };
    httpProxy = mkOption {
      type = with types; submodule {
        options = {
          host = mkOption { type = str; default = "127.0.0.1"; };
          port = mkOption { type = int; };
        };
      };
    };
    hostName = mkOption {
      type = types.str;
    };
    enableDNSACME = mkEnableOption "enable cloudflare acme secrets";
    enableBBR = mkEnableOption "use BBR as the TCP congestion control";
    sshd-greet-with-auth-info = mkEnableOption "show ssh auth info (e.g. cert identity and expiry) on ssh login" // { default = true; };
  };

  config = mkMerge [
    # fuck you GFW
    (mkIf cfg.behindGFW (
      let
        proxyUri = "http://${cfg.httpProxy.host}:${toString cfg.httpProxy.port}";
      in
      {
        assertions = [
          {
            assertion = cfg.httpProxy != null;
            message = "`httpProxy` should be set if behind GFW";
          }
        ];

        systemd.services.nix-daemon.serviceConfig.Environment = [
          "all_proxy=${proxyUri}"
          "HTTPS_PROXY=${proxyUri}"
          "HTTP_PROXY=${proxyUri}"
          "https_proxy=${proxyUri}"
          "http_proxy=${proxyUri}"
        ];

        environment.variables = {
          "all_proxy" = proxyUri;
          "ALL_PROXY" = proxyUri;
          "HTTP_PROXY" = proxyUri;
          "HTTPS_PROXY" = proxyUri;
          "http_proxy" = proxyUri;
          "https_proxy" = proxyUri;
          "NIX_REMOTE" = "daemon"; # force root to use proxy
        };

        programs.proxychains = {
          enable = true;
          proxies = {
            default = {
              enable = true;
              type = "http";
              host = cfg.httpProxy.host;
              port = cfg.httpProxy.port;
            };
          };
        };
      }
    ))

    (mkIf cfg.sshd-greet-with-auth-info {
      services.openssh.settings.ExposeAuthInfo = true;

      environment.loginShellInit =
        let
          greet = pkgs.writeShellApplication {
            name = "ssh-auth-greet";
            runtimeInputs = with pkgs; [ openssh coreutils gnused gawk ];
            text = builtins.readFile ./ssh-auth-greet.sh;
          };
        in
        "${greet}/bin/ssh-auth-greet";
    })

    (mkIf cfg.enableBBR {
      boot.kernelModules = [ "tcp_bbr" ];
      boot.kernel.sysctl = {
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
      };
    })

    # DNS ACME config
    (mkIf cfg.enableDNSACME {
      sops.secrets."cf_secret_for_acme" = { owner = lib.mkIf (builtins.hasAttr "acme" config.users.users) "acme"; };
      security.acme = {
        acceptTerms = true;
        # <host> and *.<host> share the challenge name _acme-challenge.<host> (and with
        # the wildcard CNAME, the TXT record lands on <host> itself), so concurrent
        # orders (e.g. on first deploy) overwrite each other's TXT and fail validation
        maxConcurrentRenewals = 1;
        defaults = {
          email = "acme@sharzy.in";
          dnsProvider = "cloudflare";
          environmentFile = config.sops.secrets."cf_secret_for_acme".path;
          # Since v5, lego also waits for the TXT record to show up on the system
          # resolver, not just on the authoritative nameservers. Behind tailscale
          # that is MagicDNS, which caches the NODATA from lego's first poll for
          # the SOA minimum (1800s on cloudflare), so the check outlasts lego's
          # 2-minute timeout on every retry. Let's Encrypt asks the authoritative
          # nameservers anyway, so the authoritative check alone is enough.
          extraLegoFlags = [ "--dns.propagation.disable-rns" ];
        };
      };
    })
  ];
}
