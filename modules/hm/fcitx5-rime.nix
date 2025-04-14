{ config, pkgs, lib, ... }:

with lib;
let
  baseAddons = with pkgs.rime-schemes; [
    rime-prelude
    rime-luna-pinyin
    rime-double-pinyin
    rime-essay
    rime-ice
  ];

  baseConfig = {
    "default.custom.yaml" = ''
      patch:
        schema_list:
          - schema: "double_pinyin_flypy"
    '';

    "double_pinyin_flypy.custom.yaml" = ''
      patch:
        'translator/dictionary': "rime_ice"
    '';
  };

  mkConfig = mapAttrsToList (fileName: text:
    pkgs.writeTextDir "/share/rime-data/${fileName}" text
  );
  cfg = config.setup.fcitx5-rime;
in
{
  options.setup.fcitx5-rime = {
    enable = mkEnableOption "use customized fcitx5 with rime";
    extraAddons = with types; mkOption {
      type = listOf package;
      default = [ ];
    };
    extraConfigs = mkOption { type = types.attrs; default = { }; };
  };

  config = mkIf cfg.enable {
    i18n.inputMethod = {
      enabled = "fcitx5";
      fcitx5 = {
        addons = with pkgs; [
          fcitx5-rime
          fcitx5-mozc
        ];
      };
    };
    home.file."rime-data" =
      let
        all_schemes = pkgs.symlinkJoin {
          name = "all-rime-scheme";
          paths = map
            (s: "${s}/share/rime-data")
            (
              baseAddons ++ cfg.extraAddons ++
              (mkConfig (baseConfig // cfg.extraConfigs))
            );
        };
      in
      {
        recursive = true;
        source = all_schemes;
        target = ".local/share/fcitx5/rime";
      };
  };
}
