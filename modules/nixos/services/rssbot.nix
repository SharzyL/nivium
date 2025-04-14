{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nivium.services.rssbot;
in
{
  options.nivium.services.rssbot = {
    enable = mkEnableOption "rss bot";

    package = mkPackageOption pkgs "rssbot" {
      default = "rssbot-bin";
    };

    secretFile = mkOption {
      type = types.path;
      description = ''path to a file like
      ```
      BOT_TOKEN=111111111:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
      ADMIN_ARGS=--admin 11111111 --admin 2222222
      ```
    '';
    };

    minInterval = mkOption { type = types.int; default = 300; };
    maxInterval = mkOption { type = types.int; default = 300; };
    insecure = mkOption { type = types.bool; default = false; };
  };

  config = mkIf cfg.enable {
    nivium.systemd-hardening.rssbot = {
      enable = true;
    };

    systemd.services.rssbot = {
      description = "Telegram RSS bot";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/rssbot --database %S/rssbot/sublist.json"
          + " --min-interval ${toString cfg.minInterval}"
          + " --max-interval ${toString cfg.maxInterval}"
          + " $ADMIN_ARGS $BOT_TOKEN"
          + lib.optionalString cfg.insecure " --insecure";
        EnvironmentFile = cfg.secretFile;
        StateDirectory = "rssbot";
      };
    };
  };
}
