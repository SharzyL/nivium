{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.setup.tmux;
  mkTmuxOption = options: concatStringsSep "\n" (mapAttrsToList
    (name: value:
      "set-option -g ${name} ${toString value}"
    )
    options);
  mkTmuxWindowOption = options: concatStringsSep "\n" (mapAttrsToList
    (name: value:
      "set-option -wg ${name} ${toString value}"
    )
    options);
  defaultOptions = {
    mouse = "on";
    escape-time = 10;
    terminal-overrides = "',${config.setup.defaultTerminal}:RGB'";
    renumber-windows = "on";
    allow-passthrough = "on";
  };
  colorOptions = {
    status = "on";
    status-style = "bg=colour237,fg=colour223";
    pane-active-border-style = "fg=colour250";
    pane-border-style = "fg=colour237";
    message-style = "bg=colour237,fg=colour223";
    message-command-style = "bg=colour237,fg=colour223";
    display-panes-active-colour = "colour250";
    display-panes-colour = "colour242";

    status-justify = "left";
    status-left-style = "none";
    status-left-length = 80;
    status-right-style = "none";
    status-right-length = 80;

    status-left = "'#[bg=colour241,fg=colour248] #S #[bg=colour237,fg=colour241,nobold,noitalics,nounderscore]'";
    status-right = "'#[bg=colour239,fg=colour246] %Y-%m-%d %H:%M #[bg=colour248,fg=colour237] #h '";
  };
  windowOptions = {
    clock-mode-colour = "colour109";
    window-status-bell-style = "bg=colour167,fg=colour235";
    window-status-separator = "''";
    window-status-current-format = "'#[bg=colour237,fg=colour214,nobold,noitalics,nounderscore] #[bg=colour214,fg=colour237,nobold,noitalics,nounderscore]#[bg=colour214,fg=colour239] #I#[bg=colour214,fg=colour239,bold] #W#{?window_zoomed_flag,*Z,} '";
    window-status-format = "'#[bg=colour237,fg=colour239,noitalics] #[bg=colour239,fg=colour237,noitalics]#[bg=colour239,fg=colour223] #I#[bg=colour239,fg=colour223] #W '";
  };
in
{
  options.setup.tmux = {
    enable = mkOption { type = types.bool; default = false; };
    extraScript = mkOption { type = types.str; default = ""; };
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      terminal = "tmux-256color";
      keyMode = "vi";
      historyLimit = 500000;
      customPaneNavigationAndResize = true;

      plugins = [
        {
          plugin = pkgs.tmuxPlugins.better-mouse-mode;
          extraConfig = "set -g @scroll-speed-num-lines-per-scroll 3";
        }
      ];

      extraConfig = ''
        ${mkTmuxOption defaultOptions}

        ${mkTmuxOption colorOptions}

        ${mkTmuxWindowOption windowOptions}

        bind r respawn-pane -k
        bind m select-window -l
        bind n select-pane -l

        bind -T root F12 {
          set prefix None
          set key-table off
          if -F '#{pane_in_mode}' 'send-keys -X cancel'
          set status-left "#[bg=colour248,fg=colour237] #S [locked] #[bg=colour237,fg=colour241,nobold,noitalics,nounderscore]"
          refresh-client -S
        }

        bind -T off F12 {
          set -u prefix
          set -u key-table
          set -u status-left
          refresh-client -S
        }
      '';
    };
  };
}
