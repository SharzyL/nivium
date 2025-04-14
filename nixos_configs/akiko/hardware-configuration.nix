{ config, lib, modulesPath, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.memtest86.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "nct6775" "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/7AF4-9316";
    fsType = "vfat";
  };
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/aac05792-ce14-4ed4-b80d-9216d44f486d";
    fsType = "btrfs";
    options = [ "compress=zstd" ];
  };

  fileSystems."/media/cd1" = {
    device = "/dev/sr0";
    fsType = "auto";
    options = [ "ro" "user" "noauto" "nohide" ];
  };

  fileSystems."/media/cd2" = {
    device = "/dev/sr1";
    fsType = "auto";
    options = [ "ro" "user" "noauto" "nohide" ];
  };

  # boot.initrd.luks.fido2Support = true;
  boot.initrd.luks.devices."luks_root" = {
    device = "/dev/disk/by-uuid/04cf229c-9655-4f8d-84da-2f16658525f6";
    crypttabExtraOpts = [ "fido2-device=auto" "tpm2-device=auto" ];
  };

  boot.initrd.systemd = {
    enable = true;
    tpm2.enable = true;
    emergencyAccess = true;
  };

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/5f9f4810-2f6b-47d6-89f5-fdce6662474a";
      options = [ "nofail" ];
    }
  ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
