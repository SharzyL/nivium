{ self, lib, pkgs, ... }: {

  imports = [
    ./hardware-configuration.nix
    self.nixosModules.default
  ];

  nivium = {
    hostName = "sunra";
    behindGFW = true;
    httpProxy = { port = 1094; };
    enableDNSACME = true;
    home.users."root" = {
      enable = true;
      config = {
        nivium = {
          nvim.enable = true;
          fish.enable = true;
          tmux.enable = true;
        };
      };
    };
    home.users."sharzy" = {
      enable = true;
      config = {
        nivium = {
          nvim.enable = true;
          fish.enable = true;
          tmux.enable = true;
        };
      };
    };

    services.derper = {
      enable = true;
      hostname = "sunra.d.shz.al";
      derpPort = 3043;
    };

    services.exporters = {
      enable = true;
      enableNode = true;
      enablePing = true;
    };
    services.sing-box-client.enable = true;
  };

  users.users = {
    fotile = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFJyNvQYweU38o09/F+LWtaGBmAz+gvnSedO3HVOFdrz0OyTXGtpV2iJDXYLu+RG0hZAw+7cPZT2+UFSIwfgBBDf8JXsSiXSlzcPtISxtJB/2ddCrAe8cP0cGBKykVRXsTrxD3Zsou60ld00ZdX0B98PJiyyS3R3FH0wqeOwyRT7gAZZKf5o+s+TyHGUD6XVYK4kQYBh8YakSraad8iKU5UbBwN9h0HBmH85/jv7ohYrw7+n2R0430VD79vWJqslw8SgPJCDayjhw26VcFvy1JPE7pPXB4iLw0DpVrArZKsSu1Sbul1/TSoFTseN/wdaUdnlg/8LaoXvlk/ClMAl4N"
      ] ++ pkgs.keys;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  nix.settings.substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
  };

  networking = {
    nameservers = lib.mkBefore [ "1.1.1.1" "119.29.29.29" "100.100.100.100" ];
    search = [ "hydra-bushi.ts.net" ];
  };

  documentation.man.man-db.enable = false; # building man cache is sooooo slow

  services.tailscale.enable = true;

  system.stateVersion = "22.05";
}
