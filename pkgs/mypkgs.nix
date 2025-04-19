{ lib, inputs }:

let
  map-by-name-pkgs = f: # f maps a pkg name to anything
    (lib.mapAttrs
      (name: _: f name )
      (lib.filterAttrs
        (k: v: v == "directory" && k != "_sources")
        (builtins.readDir ./by-name)
      )
    );
in
{
  makeMyPkgs = pkgs:
    inputs.flake-utils.lib.flattenTree
    (map-by-name-pkgs (name: pkgs.${name}));

  overlay = final: prev:
    (map-by-name-pkgs (name: final.callPackage (import ./by-name/${name}) { }))
    // rec {
      srcs = final.callPackage ./_sources/generated.nix { };

      vimPlugins = prev.vimPlugins.extend (final': prev': {
        vim-barbaric = final.vimUtils.buildVimPlugin {
          name = "${srcs.vim-barbaric.pname}-unstable-${srcs.vim-barbaric.date}";
          inherit (srcs.vim-barbaric) src;
        };

        filetype-nvim = final.vimUtils.buildVimPlugin {
          name = "${srcs.filetype-nvim.pname}-unstable-${srcs.filetype-nvim.date}";
          inherit (srcs.filetype-nvim) src;
        };

        tree-sitter-just = final.vimUtils.buildVimPlugin {
          name = "${srcs.tree-sitter-just.pname}-unstable-${srcs.vim-barbaric.date}";
          inherit (srcs.tree-sitter-just) src;
        };
      });
    };
}
