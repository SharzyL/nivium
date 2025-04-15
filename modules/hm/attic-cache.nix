{ config, lib, pkgs, ... }:

let
  cfg = config.nivium.attic-cache;
  getURLHost = url:
    let
      protocolRemoved = lib.last (builtins.split "[[:alnum:]]://" url); # from "https://foo.bar/xxx" to "foo.bar/xxx";
    in
    lib.head (builtins.split "/" protocolRemoved);
in
{
  options.nix.netrc = lib.mkOption {
    type = lib.types.lines;
    default = "";
  };

  options.nivium.attic-cache = with lib; {
    enable = mkEnableOption "enable attic cache nix configuration";
    caches = mkOption {
      type = types.listOf (types.submodule {
        options = {
          accessToken = mkOption { type = types.str; default = ""; };
          substituter = mkOption { type = types.str; };
          pubKey = mkOption { type = types.str; };
        };
      });
      default = [ ];
    };
  };

  config = lib.mkMerge [
    (
      lib.mkIf (config.nix.netrc != "") {
        nix.settings.netrc-file = pkgs.writeText "netrc" config.nix.netrc;
      }
    )
    (lib.mkIf cfg.enable {
      nix = {
        netrc = lib.concatLines (map
          (c: lib.optionalString (c.accessToken != "") ''
            machine ${getURLHost c.substituter} password ${c.accessToken}
          '')
          cfg.caches);
        settings = {
          extra-trusted-public-keys = map (c: c.pubKey) cfg.caches;
          extra-substituters = map (c: c.substituter) cfg.caches;
        };
      };
    })
  ];
}

