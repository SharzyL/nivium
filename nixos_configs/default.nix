{ self, inputs }:

{
  meta = {
    specialArgs = {
      inherit self inputs;
    };
    allowApplyAll = false;
    nixpkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      overlays = [ self.overlays.default ];
    };
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
}
