{ self, pkgs, ... }:

{
  imports = [
    self.nixosModules.default
    ./hardware-configuration.nix
    ./services.nix
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
  };

  nivium = {
    hostName = "jethro";
    enableDNSACME = true;

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

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "22.05";
}
