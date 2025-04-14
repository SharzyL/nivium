{ pkgs, config, ... }:

let
  ns = "lux";
  script = pkgs.writeShellApplication {
    name = "setup-netns";
    runtimeInputs = with pkgs; [ iproute2 ];
    text = builtins.readFile ./setup-netns.sh;
  };
in
{
  sops.secrets.hath_login = { sopsFile = ../../secrets/holland.yaml; };
  setup.services = {
    HentaiAtHome = {
      enable = true;
      port = 20377;
      clientLogin = config.sops.secrets.hath_login.path;
    };
  };

  systemd.services."netns-${ns}-setup" = {
    description = "setup ${ns} netns";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig.StopWhenUnneeded = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [ "${script}/bin/setup-netns" ];
      ExecStop = [ "${pkgs.iproute2}/bin/ip netns delete ${ns}" ];
    };
  };

  systemd.services.HentaiAtHome = {
    after = [ "netns-${ns}-setup.service" ];
    bindsTo = [ "netns-${ns}-setup.service" ];
    serviceConfig = {
      NetworkNamespacePath = "/run/netns/${ns}";
      PrivateNetwork = true;
    };
  };
}
