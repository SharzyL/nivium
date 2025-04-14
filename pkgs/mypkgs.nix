let
  mapPackages = f: with builtins;
    listToAttrs # { b: f "b" }
      (map
        (name: { inherit name; value = f name; })
        (filter
          (v: v != null)
          (attrValues # [ "directory" ]
            (mapAttrs # { b = "directory" }
              (k: v:
                if v == "directory" && k != "_sources" then k else null
              )
              (readDir ./by-name)  # { a = "regular", b = "directory" }
            )
          )
        )
      );
in
{
  makeMyPkgs = pkgs: mapPackages (name: pkgs.${name});

  overlay = final: prev:
    (mapPackages (name: final.callPackage (import ./by-name/${name}) { }))
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
