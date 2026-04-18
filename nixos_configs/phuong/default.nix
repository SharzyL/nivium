{ self, ... }:

{
  imports = [
    self.nixosModules.default
    ./hardware-configuration.nix
    ./services.nix
  ];

  sops.secrets."sb_secret" = { sopsFile = ../../secrets/phuong.yaml; };

  nix.gc = {
    automatic = true;
    dates = "weekly";
  };

  nivium = {
    hostName = "phuong";

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

  system.stateVersion = "25.05";
}
