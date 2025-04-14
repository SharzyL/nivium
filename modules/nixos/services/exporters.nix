{ config, lib, ... }:

with lib;
let
  cfg = config.setup.services.exporters;
in
{
  options.setup.services.exporters = {
    enable = mkEnableOption "enable exporters basic";
    enableNode = mkEnableOption "enable node exporter";
    enableSmart = mkEnableOption "enable smart exporter";
    enablePing = mkEnableOption "enable smokeping exporter";
  };

  config = mkIf cfg.enable {
    services.prometheus.exporters = {
      node = mkIf cfg.enableNode {
        enable = true;
        listenAddress = "[::]";
        port = 9100;
      };
      smartctl = mkIf cfg.enableSmart {
        enable = true;
        listenAddress = "[::]";
        port = 9101;
      };
      smokeping = mkIf cfg.enablePing {
        enable = true;
        listenAddress = "[::]";
        port = 9102;
        hosts = [
          "jethro"
          "holland"
          "oomori.d.shz.al"
        ];
      };
    };

    networking.nftables = {
      enable = true;
      ruleset = ''
        table inet exporter_filter {
          chain input {
            type filter hook input priority filter;
            tcp dport 9100-9110 iifname tailscale0 accept
            tcp dport 9100-9110 iif lo accept
            tcp dport 9100-9110 reject
          }
        }
      '';
    };
  };
}

