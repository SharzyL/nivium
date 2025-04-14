{ config, lib, self, inputs, ... }:

with lib;
let
  cfg = config.setup.home;
in
{
  options.setup.home = {
    users = mkOption {
      default = { };
      type = with types; attrsOf (submodule {
        options = {
          enable = mkEnableOption "home manager base configuration set";
          config = mkOption { type = anything; default = { }; };
        };
      });
    };
  };

  config = {
    home-manager.useGlobalPkgs = true;
    home-manager.extraSpecialArgs = { inherit self inputs; };
    home-manager.users = with builtins; mapAttrs
      (name: user:
        mkIf user.enable (mkMerge [
          ../hm
          user.config
        ])
      )
      cfg.users;
  };
}
