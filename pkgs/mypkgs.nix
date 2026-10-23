{ lib, inputs }:

let
  map-by-name-pkgs = f: # f maps a pkg name to anything
    (lib.mapAttrs
      (name: _: f name)
      (lib.filterAttrs
        (k: v: v == "directory")
        (builtins.readDir ./by-name)
      )
    );
in
{
  makeMyPkgs = pkgs:
    inputs.flake-utils.lib.flattenTree
      (map-by-name-pkgs (name: pkgs.${name}));

  overlay = final: prev:
    let
      unstableName = src: "${src.pname}-unstable-${builtins.substring 0 7 src.version}";
    in
    (map-by-name-pkgs (name: final.callPackage (import ./by-name/${name}) { }))
    // rec {
      # sources pinned by npins (./npins), in nvfetcher's { pname, version, src } shape
      srcs = lib.mapAttrs
        (name: pin: {
          pname = name;
          # url pins (rssbot) carry neither, so take the release tag from the url
          version = pin.version or pin.revision or
            (builtins.head (builtins.match ".*/releases/download/([^/]+)/.*" pin.url));
          # use nixpkgs fetchers, so sources are fetched at build time rather than at eval time;
          # npins names fetched files "source", which stdenv cannot unpack, so keep the url's file name
          src =
            if pin.type == "PyPi" || pin.type == "Url"
            then final.fetchurl { inherit (pin) url hash; }
            else pin { pkgs = final; };
        })
        (import ./npins { });

      vimPlugins = prev.vimPlugins.extend (final': prev': {
        vim-barbaric = final.vimUtils.buildVimPlugin {
          name = unstableName srcs.vim-barbaric;
          inherit (srcs.vim-barbaric) src;
        };

        filetype-nvim = final.vimUtils.buildVimPlugin {
          name = unstableName srcs.filetype-nvim;
          inherit (srcs.filetype-nvim) src;
        };

        tree-sitter-just = final.vimUtils.buildVimPlugin {
          name = unstableName srcs.tree-sitter-just;
          inherit (srcs.tree-sitter-just) src;
        };
      });
    };
}
