{ self, inputs, withSystem }:

inputs.colmena.lib.makeHive {
  meta = {
    specialArgs = {
      inherit self inputs;
    };
    allowApplyAll = false;

    # colmena requires an initialized nixpkgs, so pick an arbitrary system
    nixpkgs = withSystem "x86_64-linux" ({ pkgs, ... }: pkgs);
  };

  akiko = { ... }: {
    nixpkgs.system = "x86_64-linux";
    deployment = {
      allowLocalDeployment = true;
      targetHost = null;
      buildOnTarget = true;
    };
    imports = [ ./akiko ];
  };

  godiego = { ... }: {
    nixpkgs.system = "x86_64-linux";
    deployment = {
      allowLocalDeployment = true;
      targetHost = "godiego";
      buildOnTarget = true;
    };
    imports = [ ./godiego ];
  };

  jethro = { ... }: {
    nixpkgs.system = "x86_64-linux";
    deployment = {
      targetHost = "jethro";
      tags = [ "remote" ];
    };
    imports = [ ./jethro ];
  };

  holland = { ... }: {
    nixpkgs.system = "x86_64-linux";
    deployment = {
      targetHost = "holland";
      tags = [ "remote" ];
    };
    imports = [ ./holland ];
  };

  sunra = { ... }: {
    nixpkgs.system = "aarch64-linux";
    deployment = {
      targetHost = "sunra.d.shz.al";
      tags = [ "remote" ];
    };
    imports = [ ./sunra ];
  };
}
