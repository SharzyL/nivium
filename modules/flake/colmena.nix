{ lib, config, ... }:

let
  inherit (lib) types mkOption;
  cfg = config.flake.colmenaHive;
in
{
  options.flake.colmenaHive = mkOption {
    type = types.attrsOf types.raw;
    default = { };
  };

  config = {
    flake.nixosConfigurations = cfg.nodes;
  };
}
