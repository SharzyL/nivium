{ config, lib, ... }:

let
  cfg = config.nivium.dhack;

in
{
  options = {
    nivium.dhack = {
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

