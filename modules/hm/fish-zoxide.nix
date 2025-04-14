{ config, lib, ... }:

with lib;
let
  cfg = config.nivium.fish;
in
{
  config = mkIf cfg.enable {
    programs.zoxide = {
      enable = true;

      # we will override it
      enableFishIntegration = false;
    };

    programs.fish = {
      functions."__my_zoxide_z_complete" = ''
        set -l tokens (commandline --current-process --tokenize)
        set -l curr_tokens (commandline --cut-at-cursor --current-process --tokenize)

        if test (count $tokens) -le 2 -a (count $curr_tokens) -eq 1
            set -l query $tokens[2..-1]
            zoxide query --exclude (__zoxide_pwd) --list -- "$query"
        end
      '';

      interactiveShellInit = ''
        ${config.programs.zoxide.package}/bin/zoxide init fish | source
        complete --command __zoxide_z --no-files --arguments '(__my_zoxide_z_complete)'
      '';
    };
  };
}
