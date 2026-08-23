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
    defaultGateway = "103.70.114.1";
    defaultGateway6 = {
      address = "2401:5b60:0:2::1";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address = "103.70.114.19"; prefixLength = 24; }
        ];
        ipv6.addresses = [
          { address = "2401:5b60:0:2::13"; prefixLength = 128; }
          { address = "fe80::2da:97ff:fed6:d704"; prefixLength = 64; }
        ];
        ipv4.routes = [{ address = "103.70.114.1"; prefixLength = 32; }];
        ipv6.routes = [{ address = "2401:5b60:0:2::1"; prefixLength = 128; }];
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
    ATTR{address}=="00:da:97:d6:d7:04", NAME="eth0"
  '';
}
