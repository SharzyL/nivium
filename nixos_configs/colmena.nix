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

  jethro = { ... }: {
    nixpkgs.system = "x86_64-linux";
    deployment = {
      targetHost = "jethro.d.shz.al";
      tags = [ "remote" ];
    };
    imports = [ ./jethro ];
  };

  phuong = { ... }: {
    nixpkgs.system = "x86_64-linux";
    deployment = {
      targetHost = "phuong.d.shz.al";
      tags = [ "remote" ];
    };
    imports = [ ./phuong ];
  };

  sunra = { ... }: {
    nixpkgs.system = "x86_64-linux";
    deployment = {
      targetHost = "sunra.d.shz.al";
      tags = [ "remote" ];
    };
    imports = [ ./sunra ];
  };
}
