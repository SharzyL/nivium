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

  phuong = { ... }: {
    nixpkgs.system = "x86_64-linux";
    deployment = {
      targetHost = "160.22.16.191";
      tags = [ "remote" ];
    };
    imports = [ ./phuong ];
  };
}
