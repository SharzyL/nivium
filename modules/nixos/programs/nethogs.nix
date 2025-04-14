{ config, lib, pkgs, ... }:

let
  cfg = config.programs.nethogs;

in
{
  options = {
    programs.nethogs = {
      enable = lib.mkEnableOption (lib.mdDoc "nethogs to the global environment and configure a setcap wrapper for it");
      package = lib.mkPackageOption pkgs "nethogs" { };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    security.wrappers.nethogs = {
      owner = "root";
      group = "root";
      capabilities = "cap_net_raw,cap_net_admin+eip";
      source = "${cfg.package}/bin/nethogs";
    };
  };
}

