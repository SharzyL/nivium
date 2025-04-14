{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.loader.grub.device = "/dev/vda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };

  networking = {
    hostName = "jethro";
    nameservers = [
      "1.1.1.1"
      "9.9.9.9"
    ];
    defaultGateway = "157.119.103.1";
    defaultGateway6 = "2403:2c80:1000::1";
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address = "157.119.103.75"; prefixLength = 24; }
        ];
        ipv6.addresses = [
          { address = "2403:2c80:1000::160"; prefixLength = 48; }
          { address = "fe80::b87a:7bff:fe7a:5f3e"; prefixLength = 64; }
        ];
        ipv4.routes = [{ address = "157.119.103.1"; prefixLength = 32; }];
        ipv6.routes = [{ address = "2403:2c80:1000::1"; prefixLength = 128; }];
      };

    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="ba:7a:7b:7a:5f:3e", NAME="eth0"
  '';
}
