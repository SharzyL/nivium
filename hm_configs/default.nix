{ withSystem, inputs, self }:

let
  lib = inputs.nixpkgs.lib;

  filenames = lib.attrNames
    (lib.filterAttrs
      (k: v:
        v == "regular" && k != "default.nix"
      )
      (builtins.readDir ./.)  # { a = "regular", b = "directory" }
    );

  parseFileName = fname:
    let
      splits = builtins.split "_" (builtins.head (builtins.split "\\." fname));
      confName = builtins.head splits;
      system = if (builtins.length splits) >= 3 then (builtins.elemAt splits 2) else "x86_64-linux";
      userConfig = import ./home/${fname};
    in
    { name = confName; value = { inherit system userConfig; }; };

in

builtins.mapAttrs
  (name: { system, userConfig }:
  withSystem system ({ pkgs, ... }:
  {
    inherit pkgs;
    extraSpecialArgs = { inherit self inputs; };
    modules = [
      self.homeModules.default
      self.homeModules.standalone
      userConfig
    ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
      inputs.mac-app-util.homeManagerModules.default
    ];
  }))
  (builtins.listToAttrs (map parseFileName filenames))
