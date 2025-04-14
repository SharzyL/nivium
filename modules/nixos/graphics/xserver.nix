{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.setup.graphics.xserver;
  user = config.setup.graphics.user;
in
{
  options.setup.graphics.xserver = {
    enable = mkEnableOption "xserver base config";
  };

  config = mkIf cfg.enable {
    services.pulseaudio.enable = false;

    users.users.${user}.extraGroups = lib.mkBefore [
      "video"
      "audio"
    ];

    services = {
      libinput.enable = true;

      xserver =
        let
          user = config.setup.graphics.user;
        in
        {
          enable = true;
          xkb = {
            options = "caps:super";
            layout = "us";
          };
          displayManager.session = [{
            manage = "desktop";
            name = "hm-xsession";
            # let home-manager take care of xsession
            start = ''
              ${pkgs.runtimeShell} $HOME/${config.home-manager.users.${user}.xsession.scriptPath} &
              waitpid $!
            '';
          }];
        };

      displayManager = {
        autoLogin.user = user;
      };
    };

  };
}
