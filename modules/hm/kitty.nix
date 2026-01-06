{ config, lib, pkgs, ... }:

{
  # kitty is already added to home.packages in graphics-common.nix

  config = lib.mkIf (config.programs.kitty.enable == true) {
    programs.fish.interactiveShellInit = lib.mkAfter ''
      if [ -n "$KITTY_PID" ]
        abbr --add -- ks "kitten ssh"
      end
    '';

    programs.kitty = {
      settings = lib.mkMerge [

        {
          macos_option_as_alt = true;
          font_size = lib.mkDefault "10.0";
          window_padding_width = lib.mkDefault "2.5";
          scrollback_pager_history_size = lib.mkDefault 50;
          enabled_layouts = lib.mkDefault "splits,grid,tall,vertical,horizontal,fat,stack";

          tab_bar_style = "separator";
          tab_separator = "\"\"";
          tab_title_template =
            "\"{fmt.fg._5c6370}{fmt.bg.default}"
            + "{fmt.fg._abb2bf}{fmt.bg._5c6370}{index}"
            + "{fmt.fg._abb2bf} {title[:20]}"
            + "{fmt.fg._7209b7}{'' if num_windows == 1 else ' *' + str(num_windows)}"
            + "{fmt.fg._5c6370}{fmt.bg.default} \"";
          active_tab_title_template = "\"{fmt.fg._e5c07b}{fmt.bg.default}"
            + "{fmt.fg._335c9a}{fmt.bg._e5c07b}{index}"
            + "{fmt.fg._282c34} {title[:20]}"
            + "{fmt.fg._7209b7}{'' if num_windows == 1 else ' *' + str(num_windows)}"
            + "{fmt.fg._5e3719}{'' if layout_name == 'splits' else 'Z' if layout_name == 'stack' else '/' + layout_name}"
            + "{fmt.fg._e5c07b}{fmt.bg.default} \"";
          tab_bar_min_tabs = 1;

          inactive_border_color = "#333333";
        }
        (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          allow_remote_control = "password";
          remote_control_password = "\"\" focus-window ls";
          listen_on = "unix:\${XDG_RUNTIME_DIR}/kitty-{kitty_pid}.sock";
        })
      ];

      keybindings = {
        "ctrl+=" = "change_font_size current +1.0";
        "ctrl+-" = "change_font_size current -1.0";
        "ctrl+shift+=" = "change_font_size all +1.0";
        "ctrl+shift+-" = "change_font_size all -1.0";

        "ctrl+k>j" = "neighboring_window bottom";
        "ctrl+k>k" = "neighboring_window top";
        "ctrl+k>h" = "neighboring_window left";
        "ctrl+k>l" = "neighboring_window right";

        "ctrl+k>shift+j" = "move_window bottom";
        "ctrl+k>shift+k" = "move_window top";
        "ctrl+k>shift+h" = "move_window left";
        "ctrl+k>shift+l" = "move_window right";

        "ctrl+k>1" = "goto_tab 1";
        "ctrl+k>2" = "goto_tab 2";
        "ctrl+k>3" = "goto_tab 3";
        "ctrl+k>4" = "goto_tab 4";
        "ctrl+k>5" = "goto_tab 5";
        "ctrl+k>6" = "goto_tab 6";
        "ctrl+k>7" = "goto_tab 7";
        "ctrl+k>8" = "goto_tab 8";
        "ctrl+k>9" = "goto_tab 9";
        "ctrl+k>m" = "goto_tab -1";

        "ctrl+k>c" = "new_tab";
        "ctrl+k>x" = "close_window";
        "ctrl+k>shift+x" = "close_tab";
        "ctrl+k>z" = "toggle_layout stack"; # toggle zoom
        "alt+z" = "toggle_layout stack"; # toggle zoom
        "ctrl+k>s" = "toggle_layout splits";
        "ctrl+shift+l" = "next_layout";
        "ctrl+k>b" = "detach_window new-tab"; # break-pane
        "ctrl+k>shift+b" = "detach_tab";
        "ctrl+k>:" = "kitty_shell";
        "ctrl+p" = "nth_window -1";

        "ctrl+k>," = "set_tab_title";
        "ctrl+k>shift+," = "move_tab_backward";
        "ctrl+k>shift+." = "move_tab_forward";
        "ctrl+m" = "focus_visible_window";

        "ctrl+k>%" = "launch --location=vsplit --cwd=current";
        "ctrl+k>$" = "launch --location=vsplit";
        "ctrl+k>\"" = "launch --location=hsplit --cwd=current";
        "ctrl+k>'" = "launch --location=hsplit";
        "ctrl+k>r" = "respawn_window --cwd=current";
        "ctrl+k>shift+r" = "respawn_window";
      };
    };
  };
}
