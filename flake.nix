{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs_master.url = "nixpkgs/master";
    flake-parts.url = "flake-parts";
    flake-utils.url = "flake-utils";
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.cl-nix-lite.url = "github:r4v3n6101/cl-nix-lite/url-fix";
      inputs.treefmt-nix.follows = "treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      url = "github:SharzyL/tg_searcher/riir";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    era_ls = {
      url = "github:SharzyL/era_ls/goshujin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bww = {
      url = "github:SharzyL/bww/goshujin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chatgpt-telegram-bot = {
      url = "github:SharzyL/chatgpt-telegram-bot/goshujin";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    csync = {
      url = "github:SharzyL/csync/goshujin";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    green-rosetta = {
      url = "github:SharzyL/green_rosetta/goshujin";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    rdict = {
      url = "github:SharzyL/rdict/goshujin";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    vicishz = {
      url = "github:SharzyL/vicishz/goshujin";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    waybar = {
      url = "github:SharzyL/WayBar/feat/niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
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
        rdict
        colmena
        waybar
        vicishz
        green-rosetta
        bww
        era_ls
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
            localSystem = system;
            overlays = [ overlay ];
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
