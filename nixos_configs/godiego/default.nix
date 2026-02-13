{ config, pkgs, lib, self, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix
    ./services.nix
    self.nixosModules.default
  ];

  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [ "modesetting" ];
  services.xserver.deviceSection = ''
    Option "TearFree" "true"
  '';

  nixpkgs.config.allowUnfreePredicate = pkg:
    (builtins.elem (lib.getName pkg)
      (map lib.getName (with pkgs; [
        memtest86-efi

        cloudflare-warp
        mathematica
        wpsoffice
        dropbox
        obsidian
        parsec-bin
        zoom-us
        vscode
        snipaste
        claude-code
        codex
      ])) || lib.hasPrefix "https://www.jetbrains.com" (pkg.meta.homepage or "")
    );

  nixpkgs.config.permittedInsecurePackages = [
    # https://github.com/NixOS/nixpkgs/issues/273611
    "electron-25.9.0"
  ];

  # to allow firefox-bin used by dropbox
  nixpkgs.config.allowlistedLicenses = [
    {
      shortName = "firefox";
      fullName = "Firefox Terms of Use";
      url = "https://www.mozilla.org/about/legal/terms/firefox/";
      free = false;
      redistributable = true;
    }
  ];

  # time.timeZone = "Asia/Tokyo";

  nivium = {
    behindGFW = true;
    httpProxy = { port = 1094; };

    hostName = "godiego";
    graphics = {
      enable = true;
      niri.enable = true;
      user = "sharzy";
    };
    home.users."sharzy" = {
      enable = true;
      config = ./home.nix;
    };
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
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.memtest86.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.libinput = {
    touchpad = {
      naturalScrolling = true;
      accelSpeed = "1";
    };
  };

  hardware.acpilight.enable = true;

  networking.useDHCP = false; # let systemd manage it
  networking.wireless.iwd = {
    enable = true;
  };

  systemd.network = {
    enable = true;
    networks = {
      "ether" = {
        matchConfig.Name = "enp* wlp* wlan*";
        networkConfig.DHCP = "yes";
        dhcpV4Config.ClientIdentifier = "mac";
        dhcpV4Config.Anonymize = "yes";
        dhcpV6Config = {
          DUIDType = "uuid";
          UseDelegatedPrefix = "yes";
        };
      };
    };
    wait-online = {
      anyInterface = true;
    };
  };

  environment.systemPackages = [
    pkgs.perf
  ];

  sops.secrets.u2f_secret = {
    mode = "0444";
    sopsFile = ../../secrets/godiego.yaml;
  };

  security.pam.u2f = {
    control = "sufficient";
    settings = {
      cue = true;
      authFile = config.sops.secrets.u2f_secret.path;
    };
  };

  security.pam.services = {
    sudo.u2fAuth = true;
  };

  virtualisation.podman.enable = true;

  programs = {
    dconf.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      enableExtraSocket = true;
    };
    nexttrace.enable = true;
    nethogs.enable = true;
    iftop.enable = true;
    iotop.enable = true;
    wireshark = {
      package = pkgs.wireshark;
      enable = true;
    };
    nix-ld.enable = true;
  };

  users.users."sharzy".extraGroups = lib.mkBefore [
    "wireshark"
  ];

  sops.secrets.builder_privKey = { sopsFile = ../../secrets/desktop.yaml; };
  nix = {
    buildMachines = [{
      hostName = "builder";
      system = "x86_64-linux";
      protocol = "ssh-ng";
      maxJobs = 32;
      speedFactor = 4;
      supportedFeatures = [ "big-parallel" ];
    }];
    # distributedBuilds = true;
  };

  hardware.bluetooth.enable = true;
  services.hardware.bolt.enable = true;
  services.blueman.enable = true;

  services.tlp.enable = true;

  services.openssh = {
    listenAddresses = [
      { addr = "[::]"; port = 23333; }
      { addr = "0.0.0.0"; port = 23333; }
    ];
    settings.PermitRootLogin = "no";
  };

  services.logind = {
    settings.Login.HandlePowerKey = "ignore";
    settings.Login.HandlePowerKeyLongPress = "poweroff";
  };

  system.stateVersion = "23.05";
}
