{ config, pkgs, ... }:

{
  services.home-assistant = {
    enable = true;
    # setting extraComponents overrides the module defaults, so keep them here
    extraComponents = [
      "default_config"
      "met"
      "esphome"
      # required by xiaomi_home
      "ffmpeg"
      "zeroconf"
      # expose entities to Apple Home, configured in the UI
      "homekit"
    ];
    customComponents = [
      pkgs.home-assistant-custom-components.xiaomi_home
    ];
    config = {
      default_config = { };
      homeassistant.time_zone = config.time.timeZone;
    };
  };

  # the xiaomi_home OAuth redirect url is hardcoded to http://homeassistant.local:8123,
  # so publish this host as homeassistant.local via mDNS
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    settings = {
      server.host-name = "homeassistant";
      publish = {
        disable-publishing = false;
        publish-addresses = true;
      };
    };
  };
}
