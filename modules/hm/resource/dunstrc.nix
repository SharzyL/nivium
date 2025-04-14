{
  global = {
    monitor = "0";
    follow = "keyboard";
    width = "300";
    height = "(200,500)";
    origin = "top-right";
    offset = "10x30";
    scale = "0";
    notification_limit = "0";
    progress_bar = "true";
    progress_bar_height = "10";
    progress_bar_frame_width = "1";
    progress_bar_min_width = "150";
    progress_bar_max_width = "300";

    indicate_hidden = "yes";
    transparency = "5";
    separator_height = "2";
    padding = "10";
    horizontal_padding = "15";
    text_icon_padding = "0";
    frame_width = "2";
    frame_color = "#686de0";
    separator_color = "frame";
    corner_radius = "8";

    # Sort messages by urgency.
    sort = "yes";

    # Don't remove messages, if the user is idle (no mouse or keyboard input)
    # for longer than idle_threshold seconds.
    # Set to 0 to disable.
    # A client can set the 'transient' hint to bypass this. See the rules
    # section for how to disable this if necessary
    # idle_threshold = "120";

    font = "sans-serif 10";
    line_height = "0";

    markup = "full";
    format = "<b>%s</b>\\n%b";
    alignment = "left";
    vertical_alignment = "center";
    show_age_threshold = "60";
    ellipsize = "middle";
    ignore_newline = "no";
    stack_duplicates = "true";
    hide_duplicate_count = "false";
    icon_position = "left";
    min_icon_size = "0";
    max_icon_size = "32";
    sticky_history = "yes";
    history_length = "20";
    dmenu = "/usr/bin/dmenu -p dunst:";
    browser = "/usr/bin/xdg-open";
    always_run_script = "true";
    title = "Dunst";
    class = "Dunst";
    ignore_dbusclose = "false";
    mouse_left_click = "close_current";
    mouse_middle_click = "do_action, close_current";
    mouse_right_click = "close_all";
  };

  experimental = {
    per_monitor_dpi = "false";
  };

  urgency_low = {
    background = "#2c323b";
    foreground = "#EAEAEA";
    timeout = "10";
  };

  urgency_normal = {
    background = "#2c323b";
    foreground = "#ffffff";
    timeout = "10";
  };

  urgency_critical = {
    background = "#900000";
    foreground = "#ffffff";
    frame_color = "#ff0000";
    timeout = "0";
  };
}
