{
  pkgs,
  lib,
  nixosConfig,
  ...
}:
let

  gcfg = nixosConfig.myOptions.graphics;

  themeCfg = nixosConfig.myOptions.theme;
  baseColors = themeCfg.colors;

  monitors = gcfg.monitors;
  commonBarOpts = {
    layer = "top";
    position = "bottom";
    modules-left = [
      "hyprland/workspaces"
      "hyprland/submap"
    ];

    # clock = {
    #   "interval" = 1;
    #   "format" = "{:%a %b %d  %I:%M}";
    #   "tooltip-format" = "<tt><small>{calendar}</small></tt>";
    #   "calendar" = {
    #     "format" = {
    #       "months" = "<span color='#ffead3'><b>{}</b></span>";
    #       "today" = "<span color='#ff6699'><b>{}</b></span>";
    #     };
    #   };
    # };

    "hyprland/workspaces" = {
      show-special = true;
    };

    # --- date/time (two separate blocks with prefixes) ---
    "clock#date" = {
      interval = 1;
      format = "{:%Y-%m-%d}";
      tooltip-format = "{:%A}";
      # format-icons = [ "" ];
      # 
    };
    "clock#time" = {
      interval = 1;
      format = "{:%I:%M}";
      # format-icons = [ "" ];
    };
    battery = {
      bat = "BAT1"; # Polybar battery = "BAT1"
      adapter = "ACAD"; # Polybar adapter = "ACAD"
      states = {
        warning = 20;
        critical = 10;
      };
      format = "{capacity}% {icon}";
      format-charging = " {capacity}%";
      format-plugged = " {capacity}%";
      format-alt = "{time} {icon}";
      format-icons = [
        ""
        ""
        ""
        ""
        ""
      ];
      interval = 30;
    };

    cpu = {
      interval = 1; # Polybar had 0.5; Waybar minimum practical is ~1s
      format = "{icon} {usage:02}%";
      format-icons = [ "󰻠" ];
      # 󰻠
    };

    # --- ram ---
    # memory = {
    #   interval = 3;
    #   format = "󰍛 {free:0.1f}G/{total:0.1f}G"; # %gb_free%/%gb_total%
    #   # format-icons = [ "󰍛" ];
    #   # 󰍛
    # };

    # # --- ethernet status (enp10s0) ---
    # "network#eth" = {
    #   "interface" = "enp10s0";
    #   "interval" = 2;
    #   "format-ethernet" = " {ifname} {ipaddr} ({link_speed})";
    #   "format-disconnected" = "{ifname}: not connected";
    #   "tooltip" = true;
    # };

    # # --- ethernet speeds (separate module like your eth-speed) ---
    # "network#eth_speed" = {
    #   "interface" = "enp10s0";
    #   "interval" = 1;
    #   # Use Waybar's bandwidth placeholders (bytes or bits)
    #   "format-ethernet" = " {bandwidthDownBytes}   {bandwidthUpBytes}";
    #   "format-disconnected" = "";
    # };

    # --- filesystem (root) ---
    "disk#root" = {
      path = "/";
      interval = 30;
      format = "󰆼 {free} free of {total}";
      # format-icons = [ "󰆼" ];
      # 󰆼
    };

    "pulseaudio/slider" = {
      min = 0;
      max = 100;
      orientation = "horizontal";
    };

    tray = {
      spacing = 8;
      icons = {
        blueman = "bluetooth";
      };
    };

    mpris = {
      player = "YoutubeMusic";
      format = "{status_icon} {dynamic}";
      dynamic-order = [
        "title"
        "artist"
      ];
      status-icons = {
        paused = "󰐊";
        playing = "⏸";
      };
    };
  };

  simpleBar = commonBarOpts // {
    modules-right = [ "clock#time" ];
  };

  mainBar = commonBarOpts // {
    # eth-speed

    modules-center = [
      "mpris"
    ];

    modules-right = [
      "cpu"
      # "memory"
      "disk#root"
      # "network#eth"
      # "network#eth_speed"
      "battery"
      "clock#date"
      "clock#time"
      "pulseaudio/slider"
      "tray"
    ];

    # modules-right =
    #   "filesystem ram cpu date time "
    #   + (if nixosConfig.networking.hostName == "framework" then "battery" else "");
    # tray-position = "right";

    # modules-center = "spotify-prev spotify spotify-next";
  };

  monitorToBarCfg =
    monitorConfig:
    let
      barCfg = {
        output = "${monitorConfig.name}";
      };
      inheritedCfg = if monitorConfig.primary then mainBar else simpleBar;
    in
    inheritedCfg // barCfg;
in
{
  config = lib.mkIf gcfg.enable {
    programs.waybar = {
      enable = true;

      settings = map monitorToBarCfg monitors;

      systemd = {
        enable = true;
        target = "hyprland-session.target";
      };

      # github.com/catppuccin/waybars
      style = ''
        * {
          /* reference the color by using @color-name */
          color: @text;
          font-family: "Inter", "JetBrainsMono Nerd Font", "Symbols Nerd Font";
          font-size: 12pt;
        }

        window#waybar {
          /* you can also GTK3 CSS functions! */
          background-color: shade(@base, 0.9);
          border: 2px solid alpha(@crust, 0.3);
          padding: 0 8px;
        }

        #workspaces button { padding: 0 8px; margin: 4px 2px; border-radius: 6px; }
        #workspaces button.active { 
          background: @crust; /* rgba(255,255,255,0.10); */ 
          color: #fff;
          border-bottom: 2px solid ${baseColors.accent};
        }
        #window { padding: 0 12px; }
        #cpu, #memory, #disk, #network, #battery, #clock, #tray { padding: 0 10px; }
        #battery.critical { color: #ff6b6b; }

        /*TODO: use catppuccin colors for the slider*/
        #pulseaudio-slider slider {
            min-height: 0px;
            min-width: 0px;
            opacity: 0;
            background-image: none;
            border: none;
            box-shadow: none;
        }
        #pulseaudio-slider trough {
            min-height: 10px;
            min-width: 80px;
            border-radius: 5px;
            background-color: black;
        }
        #pulseaudio-slider highlight {
            min-width: 10px;
            border-radius: 5px;
            background-color: green;
        }
      '';
    };
  };
}
