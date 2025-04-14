{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs_master.url = "nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
    mac-app-util.url = "github:hraban/mac-app-util";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tg-searcher = {
      url = "github:SharzyL/tg_searcher/dev";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chatgpt-telegram-bot = {
      url = "github:SharzyL/chatgpt-telegram-bot/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, colmena, ... }@inputs:
    let
      mypkgs = import ./pkgs/mypkgs.nix;
    in

    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              self.overlays.default
            ];
          };
        in
        {
          formatter = pkgs.nixpkgs-fmt;
          packages = flake-utils.lib.flattenTree (mypkgs.makeMyPkgs pkgs);
          legacyPackages = pkgs;
        }
      )

    // {
      inherit inputs; # expose input for convenience of nix repl

      overlays.default = nixpkgs.lib.composeManyExtensions [
        mypkgs.overlay
        (import ./pkgs/mypkgs-overlay.nix)
        (import ./pkgs/overlay.nix { inherit inputs; })

        inputs.tg-searcher.overlays.default
        inputs.chatgpt-telegram-bot.overlays.default
      ];

      nixosConfigurations = (inputs.colmena.lib.makeHive self.colmena).nodes;

      nixosModules = import ./modules/nixos;

      homeConfigurations = builtins.mapAttrs
        (name: { system, config }:
          let
            pkgs = import inputs.nixpkgs { inherit system; overlays = [ self.overlays.default ]; };
            userConfig = config;
          in
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = { inherit self inputs; };
            modules = [
              (import ./modules/hm)
              (import ./modules/hm/standalone-base.nix)
              userConfig
            ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              inputs.mac-app-util.homeManagerModules.default
            ];
          })
        (
          with builtins;
          let
            parseFileName = fname:
              let
                splits = split "_" (head (split "\\." fname));
                confName = head splits;
                system = if (length splits) >= 3 then (elemAt splits 2) else "x86_64-linux";
                config = import ./home/${fname};
              in
              { name = confName; value = { inherit system config; }; };
            filenames = filter
              (v: v != null)
              (attrValues # [ "b" ]
                (mapAttrs # { b = "directory" }
                  (k: v:
                    if v == "regular" then k else null
                  )
                  (readDir ./hm_configs)  # { a = "regular", b = "directory" }
                )
              );
          in
          listToAttrs (map parseFileName filenames)
        );

      colmenaHive = colmena.lib.makeHive self.outputs.colmena;
      colmena = import ./nixos_configs { inherit self inputs; };
    };
}
