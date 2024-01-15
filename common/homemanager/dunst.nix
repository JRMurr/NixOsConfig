{ pkgs, lib, config, nixosConfig, ... }:
let
  gcfg = nixosConfig.myOptions.graphics;

  # https://raw.githubusercontent.com/dracula/dunst/master/dunstrc
  dunst_dracula = {
    experimental = { per_monitor_dpi = false; };
    global = {
      alignment = "left";
      always_run_script = true;
      browser = "/usr/bin/firefox -new-tab";
      class = "Dunst";
      corner_radius = "0";
      # dmenu = "/usr/bin/dmenu -p dunst:";
      ellipsize = "middle";
      follow = "mouse";
      font = "Monospace 10";
      force_xinerama = false;
      force_xwayland = false;
      format = ''
        %s %p
        %b'';
      frame_color = "#282a36";
      frame_width = "0";
      height = "300";
      hide_duplicate_count = false;
      history_length = "20";
      horizontal_padding = "10";
      # icon_path =
      #   "/usr/share/icons/gnome/16x16/status/:/usr/share/icons/gnome/16x16/devices/";
      icon_position = "left";
      idle_threshold = "120";
      ignore_dbusclose = false;
      ignore_newline = "no";
      indicate_hidden = "yes";
      line_height = "0";
      markup = "full";
      max_icon_size = "64";
      min_icon_size = "0";
      monitor = "0";
      mouse_left_click = "close_current";
      mouse_middle_click = "do_action, close_current";
      mouse_right_click = "close_all";
      notification_limit = "0";
      offset = "10x50";
      origin = "top-right";
      padding = "8";
      progress_bar = true;
      progress_bar_frame_width = "1";
      progress_bar_height = "10";
      progress_bar_max_width = "300";
      progress_bar_min_width = "150";
      scale = "0";
      separator_color = "frame";
      separator_height = "1";
      show_age_threshold = "60";
      show_indicators = "yes";
      sort = "yes";
      stack_duplicates = true;
      sticky_history = "yes";
      text_icon_padding = "0";
      title = "Dunst";
      transparency = "15";
      vertical_alignment = "center";
      width = "300";
    };
    urgency_critical = {
      background = "#ff5555";
      foreground = "#f8f8f2";
      frame_color = "#ff5555";
      timeout = "0";
    };
    urgency_low = {
      background = "#282a36";
      foreground = "#6272a4";
      timeout = "10";
    };
    urgency_normal = {
      background = "#282a36";
      foreground = "#bd93f9";
      timeout = "10";
    };
  };

in {
  config = lib.mkIf gcfg.enable {
    services.dunst = {
      enable = true;
      settings = dunst_dracula // { };
    };
  };
}
