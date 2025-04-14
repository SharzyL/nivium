{ config, lib, ... }:

let
  cfg = config.setup.systemd-hardening;
in
{
  options.setup.systemd-hardening = lib.mkOption (with lib.types; {
    type = attrsOf (submodule {
      options = {
        enable = lib.mkOption { type = bool; default = false; };
        dynamicUser = lib.mkOption { type = bool; default = true; };

        # restrictive options
        onlyLocalNetwork = lib.mkOption { type = bool; default = false; };

        # permissive options
        extraAF = lib.mkOption { type = listOf str; default = [ ]; };
        ambientCapabilities = lib.mkOption { type = listOf str; default = [ "" ]; };
        capabilityBoundingSet = lib.mkOption { type = listOf str; default = [ "" ]; };
        memoryDenyWriteExecute = lib.mkOption { type = bool; default = true; };

        # filters
        systemCallFilter = lib.mkOption {
          type = listOf str;
          default = [ "@system-service" "~@resources" "~@privileged" ];
        };
      };
    });
  });

  config.systemd.services = (lib.mapAttrs
    (serviceName: hcfg: {
      serviceConfig = lib.mkIf hcfg.enable {
        RemoveIPC = lib.mkDefault true;
        ProtectSystem = lib.mkDefault "strict";
        PrivateTmp = lib.mkDefault true;
        NoNewPrivileges = lib.mkDefault true;
        RestrictSUIDSGID = lib.mkDefault true;
        ProtectHome = lib.mkDefault true;
        UMask = lib.mkDefault "0077";

        ProtectHostname = lib.mkDefault true;
        ProtectProc = lib.mkDefault "invisible";
        ProcSubset = lib.mkDefault "pid";
        PrivateUsers = lib.mkDefault true;
        PrivateDevices = lib.mkDefault true;

        ProtectControlGroups = lib.mkDefault true;
        LockPersonality = lib.mkDefault true;
        RestrictRealtime = lib.mkDefault true;
        ProtectClock = lib.mkDefault true;
        ProtectKernelLogs = lib.mkDefault true;
        ProtectKernelTunables = lib.mkDefault true;
        ProtectKernelModules = lib.mkDefault true;
        RestrictNamespaces = lib.mkDefault true;

        SystemCallArchitectures = lib.mkDefault "native";

        DynamicUser = hcfg.dynamicUser; # implies RemoveIPC, ProtectSystem, PrivateTmp, NoNewPrivileges, RestrictSUIDSGID
        MemoryDenyWriteExecute = hcfg.memoryDenyWriteExecute;

        CapabilityBoundingSet = hcfg.capabilityBoundingSet;
        AmbientCapabilities = hcfg.ambientCapabilities;

        SystemCallFilter = hcfg.systemCallFilter;

        RestrictNetworkInterfaces = lib.mkIf hcfg.onlyLocalNetwork [ "lo" ];
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ] ++ hcfg.extraAF;
      };
    }
    )
    cfg);
}
