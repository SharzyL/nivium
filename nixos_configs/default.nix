{ self, inputs, overlay }:

let
  lib = inputs.nixpkgs.lib;

  # deployment targets live in ../nsw.yaml
  hosts = {
    akiko = "x86_64-linux";
    phuong = "x86_64-linux";
    sunra = "x86_64-linux";
    tamao = "x86_64-linux";
  };
in

lib.mapAttrs
  (name: system: lib.nixosSystem {
    specialArgs = { inherit self inputs; };
    modules = [
      ./${name}
      {
        nixpkgs.hostPlatform = system;
        nixpkgs.overlays = [ overlay ];
      }
    ];
  })
  hosts
