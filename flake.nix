{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs_master.url = "nixpkgs/master";
    flake-parts.url = "flake-parts";
    flake-utils.url = "flake-utils";
    mac-app-util.url = "github:hraban/mac-app-util";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    csync = {
      url = "github:SharzyL/csync/goshujin";
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

  outputs = { flake-parts, ... }@inputs:
    let
      lib = inputs.nixpkgs.lib;
      mypkgs = import ./pkgs/mypkgs.nix { inherit lib inputs; };
      overlay = lib.composeManyExtensions ([
        mypkgs.overlay
        (import ./pkgs/mypkgs-overlay.nix)
        (import ./pkgs/overlay.nix { inherit inputs; })
      ] ++ (map (f: f.overlays.default) (with inputs; [
        tg-searcher
        chatgpt-telegram-bot
        csync
        colmena
      ])));
    in
    flake-parts.lib.mkFlake { inherit inputs; }
      ({ self, config, withSystem, ... }: {
        imports = [
          inputs.treefmt-nix.flakeModule
          inputs.home-manager.flakeModules.home-manager
          ./modules/flake/colmena.nix
        ];

        systems = lib.systems.flakeExposed;

        perSystem = { system, pkgs, ... }: {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ overlay ];

            # to make `nix flake check` happy
            config.allowUnfreePredicate = pkg:
              builtins.elem (lib.getName pkg) [ "utools" ];
          };

          packages = mypkgs.makeMyPkgs pkgs;

          legacyPackages = pkgs;
          treefmt.programs = {
            nixpkgs-fmt.enable = true;
            stylua = {
              settings = {
                indent_type = "Spaces";
                indent_width = 2;
                quote_style = "AutoPreferSingle";
              };
              enable = true;
            };
            shellcheck.enable = true;
            black.enable = true;
          };
        };

        flake = {
          inherit inputs;
          nixosModules.default = import ./modules/nixos;

          homeModules = {
            default = import ./modules/hm;
            standalone = import ./modules/hm/standalone-base.nix;
          };

          # TODO: find out why lib.modules.importApply not working
          homeConfigurations = import ./hm_configs {
            inherit self inputs withSystem;
          };

          colmenaHive = import ./nixos_configs/colmena.nix {
            inherit self inputs withSystem;
          };
        };
      });
}
