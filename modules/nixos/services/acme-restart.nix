{ lib, config, ... }:

let
  cfg = config.setup.services.acme-restart;
in
{
  options = {
    setup.services.acme-restart = lib.mkOption {
      type = with lib.types; attrsOf (submodule (
        {
          options = {
            certNames = lib.mkOption { type = listOf str; };
            servicesToRestart = lib.mkOption { type = listOf str; };
          };
        }
      ));
      default = { };
    };
  };

  config = {
    systemd.services = lib.mapAttrs'
      (name: restartConf:
        lib.nameValuePair "acme-restart-${name}"
          (
            let
              inherit (restartConf) certNames servicesToRestart;
              certs = config.security.acme.certs;
              sslServices = map (certName: "acme-${certName}.service") certNames;
              sslTargets = map (certName: "acme-finished-${certName}.target") certNames;
            in
            {
              wants = servicesToRestart;
              wantedBy = sslServices ++ [ "multi-user.target" ];
              # Before the finished targets, after the renew services.
              # This service might be needed for HTTP-01 challenges, but we only want to confirm
              # certs are updated _after_ config has been reloaded.
              before = sslTargets;
              after = sslServices;
              # Block reloading if not all certs exist yet.
              # Happens when config changes add new vhosts/certs.
              unitConfig.ConditionPathExists =
                lib.optionals
                  (sslServices != [ ])
                  (map (certName: certs.${certName}.directory + "/fullchain.pem") certNames);
              serviceConfig = {
                Type = "oneshot";
                TimeoutSec = 60;
                ExecCondition = "/run/current-system/systemd/bin/systemctl -q is-active ${builtins.toString servicesToRestart}";
                ExecStart = "/run/current-system/systemd/bin/systemctl restart ${builtins.toString servicesToRestart}";
              };
            }
          )
      )
      cfg;
  };
}

