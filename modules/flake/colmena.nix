{ lib, inputs, config, ... }:

let
  inherit (lib) types mkOption;
  inherit (inputs) colmena;
  cfg = config.flake.colmenaConfigurations;
in
{
  options.flake.colmenaConfigurations = mkOption {
    type = types.lazyAttrsOf types.raw;
    default = { };
  };

  options.flake.colmenaHive = mkOption {
    type = types.lazyAttrsOf types.raw;
    default = { };
  };

  config = {
    flake.nixosConfigurations = (colmena.lib.makeHive cfg).nodes;
    flake.colmenaHive = colmena.lib.makeHive cfg;
  };
}
