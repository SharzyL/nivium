{ config, lib, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/profiles/qemu-guest.nix")
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/812bc4a9-effd-4cd8-bfb7-7d306cd73e5a";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" ];
  };

  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/812bc4a9-effd-4cd8-bfb7-7d306cd73e5a";
    fsType = "btrfs";
    options = [ "subvol=@swap" "noatime" ];
  };

  swapDevices = [{
    device = "/swap/swapfile";
    size = 4096;
  }];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
