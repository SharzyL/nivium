{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.programs.yazi.enable {
    programs.yazi = {
      enableFishIntegration = true; # make our own fish integration

      keymap = {
        mgr.prepend_keymap = [
          { on = [ "g" "d" ]; run = "cd ${config.xdg.userDirs.download}"; desc = "Go to the downloads directory"; }
          { on = [ "g" "t" ]; run = "cd ~/tmp"; desc = "Go to user tmp"; }
          { on = [ "g" "T" ]; run = "cd /tmp"; desc = "Go to global tmp"; }

          { on = [ "<Enter>" ]; run = "enter"; desc = "Enter the child directory"; }
        ];
        tasks.prepend_keymap = [
          { on = [ "q" ]; run = "close"; desc = "Hide the task manager"; }
        ];
      };

      theme.flavor = {
        dark = "catppuccin-mocha";
      };

      flavors = { catppuccin-mocha = "${pkgs.srcs.yazi-flavors.src}/catppuccin-mocha.yazi"; };
    };

  };
}
