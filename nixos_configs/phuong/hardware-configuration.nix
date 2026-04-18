{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.loader.grub.device = "/dev/vda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = { device = "/dev/disk/by-uuid/0c93f6bc-ef9c-468d-be02-84b4a70d3678"; fsType = "xfs"; };

  zramSwap.enable = true;

  networking = {
    nameservers = [
      "8.8.8.8"
      "8.8.4.4"
      "2001:4860:4860::8888"
      "2001:4860:4860::8844"
    ];
    defaultGateway = "160.22.16.1";
    defaultGateway6 = {
      address = "2400:e920:0:8::1";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address = "160.22.16.191"; prefixLength = 24; }
        ];
        ipv6.addresses = [
          { address = "2400:e920:0:8::3d"; prefixLength = 128; }
          { address = "fe80::24a:e9ff:fefe:ef6a"; prefixLength = 64; }
        ];
        ipv4.routes = [{ address = "160.22.16.1"; prefixLength = 32; }];
        ipv6.routes = [{ address = "2400:e920:0:8::1"; prefixLength = 128; }];
      };
    };
    tempAddresses = "disabled";
  };

  # prevent ra
  boot.kernel.sysctl = {
    "net.ipv6.conf.eth0.accept_ra" = 0;
    "net.ipv6.conf.eth0.autoconf" = 0;
    "net.ipv6.conf.eth0.temp_prefererred_lft" = 0;
  };

  services.udev.extraRules = ''
    ATTR{address}=="00:4a:e9:fe:ef:6a", NAME="eth0"
  '';
}
