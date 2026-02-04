{ config, ... }:

{
  sops.secrets."rosetta_env" = { sopsFile = ../../../secrets/akiko.yaml; };

  services.green-rosetta = {
    enable = true;
    listen = "127.0.0.1:2445";
    configFile = ./green-rosetta.toml;
    envFile = config.sops.secrets."rosetta_env".path;
  };
}
