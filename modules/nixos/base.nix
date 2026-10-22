{ config, pkgs, lib, ... }:

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
    nix-remote = {
      enable = mkEnableOption "enable remote nix builder";
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
  };

  config = mkMerge [
    # general config
    {
      sops = {
        defaultSopsFile = ../../secrets/general.yaml;
        age = {
          keyFile = lib.mkDefault "/var/lib/nivium/sops.key";
          sshKeyPaths = [ ];
        };
        gnupg.sshKeyPaths = [ ];

        secrets."user_passwd" = { neededForUsers = true; };
      };

      systemd.tmpfiles.rules = [ "d /var/lib/nivium 0755 root root - -" ];

      security.sudo.extraConfig = ''
        Defaults lecture="never"
      '';

      nix = {
        package = pkgs.nixVersions.latest;
        channel.enable = false;
        settings = {
          trusted-users = mkBefore [ "root" cfg.adminUser ];
          experimental-features = mkBefore [ "nix-command" "flakes" "auto-allocate-uids" "cgroups" "ca-derivations" ];
          use-xdg-base-directories = true;
          auto-optimise-store = mkDefault true;
          builders-use-substitutes = false;
          use-cgroups = true;
        };
      };

      time.timeZone = mkDefault "Asia/Shanghai";

      users.defaultUserShell = pkgs.fish;
      programs = {
        command-not-found.enable = false;
        fish = {
          enable = true;
          useBabelfish = true;
        };
        neovim = {
          enable = true;
          defaultEditor = true;
        };

        gnupg.agent = {
          enable = true;
          enableSSHSupport = mkDefault true;
          enableExtraSocket = true;
        };
      };

      users.mutableUsers = false;
      users.users = {
        root = {
          openssh.authorizedKeys.keys = pkgs.keys;
          hashedPasswordFile = config.sops.secrets."user_passwd".path;
        };

        sharzy = {
          uid = mkDefault 1000;
          isNormalUser = mkDefault true;
          extraGroups = mkBefore [ "wheel" ];
          hashedPasswordFile = config.sops.secrets."user_passwd".path;
          openssh.authorizedKeys.keys = pkgs.keys;
        };
      };

      security.pki.caCertificateBlacklist = [
        "Comodo AAA Services root"
        "emSign ECC Root CA - G3"
      ];

      environment.etc."ssh/trusted_user_ca_keys".text = ''
        ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIa1ySKa6MhJmDYECMefviL6eWB/vuJzH51i8LR/9T76Ezrwc/PnNOhHyJAH7zAgEX95QN8M8VuD5Xbs1ugqyuU= sharzy-akiko-ca
      '';

      services.openssh = {
        enable = mkDefault true;
        listenAddresses = mkBefore [
          { addr = "[::]"; port = 22; }
          { addr = "0.0.0.0"; port = 22; }
        ];
        settings.PasswordAuthentication = mkDefault false;
        settings.TrustedUserCAKeys = "/etc/ssh/trusted_user_ca_keys";
        extraConfig = mkAfter ''
          StreamLocalBindUnlink yes
          LoginGraceTime 0
        '';
      };

      i18n = {
        defaultLocale = "en_US.UTF-8";
      };

      networking = {
        firewall.enable = mkDefault false;
        hostName = cfg.hostName;
      };
    }

    # nix-remote config
    (mkIf cfg.nix-remote.enable {
      users.users.nix-remote = {
        uid = mkDefault 2000;
        isNormalUser = mkDefault true;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCUYFsDs2RhQTC6PkAqo9FZzNIPB0TwAbjC3pnFCAta nix-remote"
        ];
      };
    })

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

    # DNS ACME config
    (mkIf cfg.enableDNSACME {
      sops.secrets."cf_secret_for_acme" = { owner = lib.mkIf (builtins.hasAttr "acme" config.users.users) "acme"; };
      security.acme = {
        acceptTerms = true;
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
