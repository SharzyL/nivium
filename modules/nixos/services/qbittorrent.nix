{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.nivium.services.qbittorrent;
in
{
  options = {
    nivium.services.qbittorrent = {
      enable = mkEnableOption "qbittorrent client";
      download-dir = mkOption { type = types.str; };

      package = mkPackageOption pkgs "qbittorrent-nox" { };
      webui-port = mkOption { type = types.port; default = 8080; };

      user = mkOption {
        type = types.str;
        default = "qbittorrent";
      };

      group = mkOption {
        type = types.str;
        default = "qbittorrent";
      };
    };
  };

  config = mkIf cfg.enable {
    users.users = optionalAttrs (cfg.user == "qbittorrent") ({
      qbittorrent = {
        group = cfg.group;
        isSystemUser = true;
        description = "qbittorrent BitTorrent user";
      };
    });

    users.groups = optionalAttrs (cfg.group == "qbittorrent") ({
      qbittorrent = { };
    });

    nivium.systemd-hardening.qbittorrent = {
      enable = true;
      dynamicUser = false; # it writes files to torrent directory
      extraAF = [ "AF_NETLINK" ];
    };

    systemd.services.qbittorrent = {
      description = "qbittorrent";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/qbittorrent-nox"
          + " --webui-port=${toString cfg.webui-port}";

        WorkingDirectory = "%S/qbittorrent";
        CacheDirectory = "qbittorrent";
        StateDirectory = [
          "qbittorrent"
          "qbittorrent/config"
          "qbittorrent/data"
        ];
        StateDirectoryMode = "0750";
        CacheDirectoryMode = "0750";
        ReadWritePaths = [ cfg.download-dir ];
        UMask = "007";
        Environment = [
          "XDG_CACHE_HOME=%C/qbittorrent"
          "XDG_CONFIG_HOME=%S/qbittorrent/config"
          "XDG_DATA_HOME=%S/qbittorrent/data"
        ];
        User = cfg.user;
        Group = cfg.group;
      };
    };
  };
}
