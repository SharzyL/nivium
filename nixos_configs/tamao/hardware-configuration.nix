{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.loader.grub.device = "/dev/vda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];
  boot.kernelParams = [ "console=ttyS0,115200" "console=tty0" ];
  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };

  zramSwap.enable = true;
  systemd.oomd.enable = false;
  services.earlyoom.enable = true;

  networking = {
    hostName = "tamao";
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
    defaultGateway = "45.142.127.1";
    defaultGateway6 = { address = "2a12:a301:2003::1"; interface = "eth0"; };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address = "45.142.127.100"; prefixLength = 24; }
        ];
        ipv6.addresses = [
          { address = "2a12:a301:2003::109d"; prefixLength = 48; }
          { address = "fe80::fa1d:a1ff:fe80:52f1"; prefixLength = 64; }
        ];
        ipv4.routes = [{ address = "45.142.127.1"; prefixLength = 32; }];
        ipv6.routes = [{ address = "2a12:a301:2003::1"; prefixLength = 128; }];
      };
    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="f8:1d:a1:80:52:f1", NAME="eth0"
  '';
}
