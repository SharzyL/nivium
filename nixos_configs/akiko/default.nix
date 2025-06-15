{ config, pkgs, lib, self, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./services.nix
    self.nixosModules.default
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    (builtins.elem (lib.getName pkg)
      (map lib.getName (with pkgs; [
        memtest86-efi
        linuxPackages.nvidia_x11
        linuxPackages.nvidia_x11.settings

        cloudflare-warp
        mathematica
        wpsoffice
        dropbox
        obsidian
        parsec-bin
        zoom-us
        vscode
        mlc
        utools
      ])) || lib.hasPrefix "https://www.jetbrains.com" (pkg.meta.homepage or "")
    || (pkg.meta.licence.shortName or "" == "firefox")
    );

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


  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = false;
    nvidiaSettings = true;
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  boot.extraModprobeConfig = ''
    options nvidia "NVreg_RestrictProfilingToAdminUsers=0"
  '';

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

  nivium = {
    behindGFW = true;
    httpProxy = { port = 1094; };

    hostName = "akiko";
    nix-remote.enable = true;
    graphics = {
      enable = true;
      xserver.enable = true;
      hidpi.enable = true;
      i3lock.enable = true;
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

  services.libinput = {
    touchpad = {
      naturalScrolling = true;
      accelSpeed = "1";
    };
  };

  services.zram-generator = {
    enable = true;
    settings.zram0 = {
      compression-algorithm = "zstd";
      zram-size = "ram";
    };
  };

  # services.xserver.displayManager.setupCommands = ''
  #   ${pkgs.xorg.xrandr}/bin/xrandr --output DP-2 --primary --left-of DP-0
  # '';

  networking.useDHCP = false; # let systemd manage it
  systemd.network = {
    enable = true;
    networks = {
      "ether" = {
        matchConfig.Name = "enp* wlp*";
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

  networking.wireless.iwd = {
    enable = true;
  };

  boot.supportedFilesystems = [ "zfs" "nfs4" ];
  boot.zfs.extraPools = [ "tank" ];
  networking.hostId = "2741c380"; # first 8 chars of /etc/machine-id, required by ZFS
  services.zfs.autoScrub.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  environment.systemPackages = [
    config.boot.kernelPackages.perf
  ];

  sops.secrets.u2f_secret = {
    mode = "0444";
    sopsFile = ../../secrets/akiko.yaml;
  };

  security.pam.u2f = {
    control = "sufficient";
    settings = {
      cue = true;
      authfile = config.sops.secrets.u2f_secret.path;
    };
  };

  security.pam.services.sudo.u2fAuth = true;

  security.auditd.enable = true;

  virtualisation.podman.enable = true;

  virtualisation.virtualbox.host.enable = true;

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      enableExtraSocket = true;
    };
    gnome-disks.enable = true;
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
  environment.stub-ld.enable = false;

  users.users."sharzy".extraGroups = lib.mkBefore [ "wireshark" "cdrom" "vboxusers" ];

  i18n.supportedLocales = [ "all" ];

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  services.openssh = {
    listenAddresses = [
      { addr = "[::]"; port = 23333; }
      { addr = "0.0.0.0"; port = 23333; }
    ];
    settings.PermitRootLogin = "no";
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  system.stateVersion = "22.05";

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
    interval = "weekly";
  };
}
