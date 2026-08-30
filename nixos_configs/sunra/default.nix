{ self, config, ... }: {
  imports = [
    self.nixosModules.default
    ./hardware-configuration.nix
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
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
  };

  # holds the [server] section of the rathole config, i.e. default_token
  sops.secrets."rathole_token" = { sopsFile = ../../secrets/sunra.yaml; };

  # expose akiko's sshd (which listens on 23333) as sunra:23333
  services.rathole = {
    enable = true;
    role = "server";
    credentialsFile = config.sops.secrets."rathole_token".path;
    settings.server = {
      bind_addr = "0.0.0.0:24333";
      services.akiko_ssh.bind_addr = "0.0.0.0:23333";
    };
  };

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.05";

  zramSwap.enable = true;
}
