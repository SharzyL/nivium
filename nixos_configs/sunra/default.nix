{ self, config, ... }: {
  imports = [
    self.nixosModules.default
    ./hardware-configuration.nix
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nivium = {
    hostName = "sunra";

    home.users."root" = {
      enable = true;
      config = {
        nivium = {
          profile = "minimal";
          nvim.enable = true;
          fish.enable = true;
        };
      };
    };

    home.users."sharzy" = {
      enable = true;
      config = {
        nivium = {
          profile = "minimal";
          nvim.enable = true;
          fish.enable = true;
        };
      };
    };

    behindGFW = true;
    httpProxy = { port = 1094; };
    services.mihomo.enable = true;
  };

  # holds the [server] section of the rathole config, i.e. default_token
  sops.secrets."rathole_token" = { sopsFile = ../../secrets/sunra.yaml; };

  # expose akiko's sshd as sunra:23333
  services.rathole = {
    enable = true;
    role = "server";
    credentialsFile = config.sops.secrets."rathole_token".path;
    settings.server = {
      bind_addr = "0.0.0.0:24333";
      services.akiko_ssh.bind_addr = "0.0.0.0:23333";
    };
  };

  services.tailscale = {
    enable = true;
  };

  # DHCP hands out Alibaba's VPC resolvers 100.100.2.136/138, which sit inside
  # tailscale's CGNAT range; tailscale's ts-input chain drops their replies as
  # spoofed, so every forwarded query times out. Use public resolvers instead.
  networking.nameservers = [ "223.5.5.5" "119.29.29.29" ];
  networking.dhcpcd.extraConfig = "nohook resolv.conf";

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.05";

  zramSwap.enable = true;
}
