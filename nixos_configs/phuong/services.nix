{ config, ... }:

let
  hostName = "phuong.d.shz.al";
in
{
  sops.secrets."sb_secret" = { sopsFile = ../../secrets/phuong.yaml; };
  sops.secrets."chatgpt_bot" = { sopsFile = ../../secrets/phuong.yaml; };

  nivium = {
    enableDNSACME = true;
    services.sing-box-server = {
      enable = true;
      host = hostName;
      clients = [
        { password = { _secret_from_env = "pwd1"; }; name = "u1"; }
      ];
      envFile = config.sops.secrets."sb_secret".path;
    };
  };

  services.chatgpt-telegram-bot = {
    enable = true;
    envFile = config.sops.secrets."chatgpt_bot".path;
    configFile = ./etc/chatgpt.toml;
  };
}
