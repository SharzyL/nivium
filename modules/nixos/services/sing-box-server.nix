{ config, lib, pkgs, utils, ... }:

with lib;
let
  cfg = config.nivium.services.sing-box-server;
  sbCfg = config.services.sing-box;
  genJqSecretsEnvReplacementSnippet' = attr: set: output:
    let
      secrets = utils.recursiveGetAttrWithJqPrefix set attr;
      stringOrDefault = str: def: if str == "" then def else str;
    in
    ''
      if [[ -h '${output}' ]]; then
        rm '${output}'
      fi

      inherit_errexit_enabled=0
      shopt -pq inherit_errexit && inherit_errexit_enabled=1
      shopt -s inherit_errexit
    ''
    + "\n"
    + "${pkgs.jq}/bin/jq > ${output} "
    + lib.escapeShellArg (stringOrDefault
      (concatStringsSep
        " | "
        (imap1 (index: name: ''${name} = $ENV.${secrets.${name}}'')
          (attrNames secrets)))
      ".")
    + ''
       <<'EOF'
      ${builtins.toJSON set}
      EOF
      (( ! $inherit_errexit_enabled )) && shopt -u inherit_errexit
    '';
  genJqSecretsEnvReplacementSnippet = genJqSecretsEnvReplacementSnippet' "_secret_from_env";
in
{
  options.nivium.services.sing-box-server = {
    enable = mkEnableOption "sing-box server";
    host = mkOption { type = types.str; };
    port = mkOption { type = types.port; default = 7853; };
    listen = mkOption { type = types.str; default = "0.0.0.0"; };
    loglevel = mkOption { type = types.str; default = "warning"; };
    clients = mkOption {
      type = types.listOf (types.submodule {
        options = {
          password = mkOption { type = types.anything; }; # use any allow injecting secrets
          name = mkOption { type = types.str; };
        };
      });
    };
    envFile = mkOption { type = types.nullOr types.path; default = null; };
  };

  config = mkIf cfg.enable {
    security.acme.certs.${cfg.host} = { };

    services.sing-box = {
      enable = true;
      settings = {
        log.level = cfg.loglevel;
        outbounds = [
          { type = "direct"; tag = "direct"; }
          { type = "block"; tag = "block"; }
        ];
        route = {
          rules = [
            { ip_is_private = true; outbound = "block"; }
          ];
        };
        inbounds = [{
          listen = cfg.listen;
          listen_port = cfg.port;
          type = "trojan";
          users = cfg.clients;
          tls = {
            enabled = true;
            server_name = cfg.host;
            certificate_path = "/var/lib/acme/${cfg.host}/cert.pem";
            key_path = "/var/lib/acme/${cfg.host}/key.pem";
          };
          multiplex.enabled = true;
        }];
      };
    };

    # TODO: user sing-box is used to build config, remove it!
    nivium.systemd-hardening.sing-box = {
      enable = true;
      extraAF = [ "AF_NETLINK" ];
    };
    systemd.services.sing-box = {
      preStart = lib.mkForce ''
        umask 0077
        mkdir -p /etc/sing-box
        ${genJqSecretsEnvReplacementSnippet sbCfg.settings "\${RUNTIME_DIRECTORY}/config.json"}
      '';

      serviceConfig = {
        SupplementaryGroups = [ "acme" ];
        EnvironmentFile = cfg.envFile;
      };
    };
  };
}
