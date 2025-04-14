{ config, lib, ... }:

let
  cfg = config.setup.dhack;

in
{
  options = {
    setup.dhack = {
      enable = lib.mkEnableOption (lib.mdDoc "dhack kernel module");
    };
  };

  config = lib.mkIf cfg.enable {
    boot.extraModulePackages = [
      (config.boot.kernelPackages.callPackage ./dhack.nix { })
    ];

    boot.kernelModules = [ "dhack" ];
  };
}

