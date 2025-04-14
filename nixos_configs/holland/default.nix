{ self, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./services.nix
      ./hath.nix
      self.nixosModules.default
    ];

  setup = {
    hostName = "holland";

    home.users."root" = {
      enable = true;
      config = {
        setup = {
          nvim.enable = true;
          fish.enable = true;
          tmux.enable = true;
        };
      };
    };

    home.users."sharzy" = {
      enable = true;
      config = {
        setup = {
          nvim.enable = true;
          fish.enable = true;
          tmux.enable = true;
        };
      };
    };
  };

  networking = {
    hostName = "holland";
    interfaces = {
      ens18 = {
        ipv4.addresses = [
          {
            address = "10.0.1.103";
            prefixLength = 24;
          }
        ];
        ipv6.addresses = [
          {
            address = "2a01:4f9:4a:286f:1:103:0:1";
            prefixLength = 80;
          }
        ];
      };
    };
    defaultGateway = {
      address = "10.0.1.1";
      interface = "ens18";
    };
    defaultGateway6 = {
      address = "2a01:4f9:4a:286f:1::1";
      interface = "ens18";
    };
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
  };

  services.openssh = {
    listenAddresses = [{ addr = "0.0.0.0"; port = 20322; }];
  };

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "22.05"; # Did you read the comment?
}

