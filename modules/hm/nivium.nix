{ config, pkgs, lib, ... }:

# the `nivium.*` options and the config each toggle turns on

with lib;
let
  cfg = config.nivium;
in
{
  options.nivium = {
    profile = mkOption {
      # bare: has fish
      # minimal: has nvim
      # full: has nvim and lsp and some extra tools
      type = types.enum [ "full" "minimal" "bare" ];
      default = "full";
    };
    bashProfileExecFish = mkOption {
      type = types.bool;
      default = false;
    };
    is-trusted-user = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether the user is in nix's `trusted-users`. Some nix.conf settings
        (e.g. `use-xdg-base-directories`) are ignored with a warning for
        untrusted users, so they are only set when this is true.
      '';
    };
  };

  config = mkMerge [
    (mkIf (cfg.profile == "full") {
      home.packages = with pkgs; [
        nh
        cmake
        ninja
        gnumake
        trash-cli
        just
        sharzyscripts.sysutils
        iets
        nix-output-monitor
      ];
      programs.yazi.enable = true;
    })

    (mkIf cfg.bashProfileExecFish {
      home.file.".bash_profile".text = ''
        if [[ $- == *i* ]] && which fish >/dev/null; then
          exec fish
        fi
      '';
    })

    (mkIf cfg.is-trusted-user {
      nix.settings.use-xdg-base-directories = true;
    })
  ];
}
