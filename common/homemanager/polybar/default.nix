{ pkgs, lib, config, ... }:
# TODO: add https://github.com/PrayagS/polybar-spotify
let
  # TODO: make these declared in module.nix and use them in i3, polybar, and autorandr
  mainMonitor = "DP-0";
  topMonitor = "HDMI-0";
  sideMonitor = "USB-C-0";
in {
  # try to use stuff from https://github.com/adi1090x/polybar-themes
  # this looks good https://github.com/adi1090x/polybar-themes/tree/master/simple/material
  # environment.systemPackages = " pkgs.pywal " {;

  home.packages = with pkgs; [ zscroll playerctl ];
  services.playerctld.enable = true;

  xdg.configFile = {
    "poly-get-spotify-status" = {
      source = ./scripts/poly-get-spotify-status.sh;
      target = "polybar/scripts/poly-get-spotify-status.sh";
      executable = true;
    };
    "poly-scroll-spotify" = {
      source = ./scripts/poly-scroll-spotify.sh;
      target = "polybar/scripts/poly-scroll-spotify.sh";
      executable = true;
    };
  };

  services = {
    polybar = {
      enable = true;
      package = pkgs.polybarFull;
      script = ''
        polybar --reload main & disown;
        polybar --reload top & disown;
        polybar --reload side & disown;
      '';
      settings = rec {

        colors = {
          background = "#1F1F1F";
          background-alt = "#3f3f3f";
          foreground = "#FFFFFF";
          foreground-alt = "#8F8F8F";
          module-fg = "#1F1F1F";
          primary = "#ffb300";
          secondary = "#E53935";
          alternate = "#7cb342";
        };

        formatting = {
          fixed-center = true;
          background = "${colors.background}";
          foreground = "${colors.foreground}";
          line-size = 2;
          line-color = "${colors.primary}";
          border-size = 3;
          border-color = "${colors.background}";
          tray-background = "${colors.background}";
          module-margin-left = 2;
          module-margin-right = 2;
          font = [
            "Fantasque Sans Mono:pixelsize=12;3"
            "Material-Design-Iconic-Font:size=13;4"
            "Iosevka Term:size=15:weight=bold;3"
          ];
        };

        commonBarOpts = formatting // {
          bottom = true;
          enable-ipc = true;
          modules-left = "i3";
        };

        # barConf = commonBarOpts // {
        #   # modules-center = "title";
        #   modules-right = "eth-speed ram cpu date time";
        # };

        simpleBar = commonBarOpts // { modules-right = "time"; };

        "bar/main" = commonBarOpts // {
          monitor = "${mainMonitor}";
          modules-right = "filesystem eth-speed ram cpu date time";
          tray-position = "right";
        };
        "bar/side" = simpleBar // {
          monitor = "${sideMonitor}";
          enable-ipc = true;
          # modules-center =
          #   "spotify spotify-prev spotify-play-pause spotify-next";
        };
        "bar/top" = simpleBar // { monitor = "${topMonitor}"; };

        "module/date" = {
          type = "internal/date";
          interval = 1;
          date = " %Y-%m-%d";
          label = "%date%";
          format-prefix = " ";
        };

        "module/time" = {
          type = "internal/date";
          interval = 1;
          time = "%H:%M";
          label = "%time%";
          format-prefix = " ";
        };

        "module/title" = {
          type = "internal/xwindow";
          label = "%title%";
          format = "<label>";
          format-font = 4;
          label-maxlen = 30;
        };

        "module/cpu" = {
          type = "internal/cpu";
          interval = "0.5";
          format = "<label>";
          label = "﬙ %percentage%%";
        };

        "module/ram" = {
          type = "internal/memory";
          interval = 3;
          format = "<label>";
          label = " %gb_free%/%gb_total%";
        };

        "module/eth" = {
          type = "internal/network";
          interface = "enp10s0";
          interval = 2;
          ping-interval = 2;

          format-connected = "<label-connected>";
          format-disconnected = "<label-disconnected>";
          format-packetloss = "<label-connected>";

          label-connected = " %ifname% %local_ip%  (%linkspeed%)";
          label-disconnected = "%ifname: not connected";
        };

        "module/eth-speed" = {
          type = "internal/network";
          interface = "enp10s0";
          interval = "0.5";
          ping-interval = 1;

          format-connected = "<label-connected>";
          format-disconnected = "";
          format-packetloss = "";
          label-connected = " %downspeed%   %upspeed%";
        };

        "module/filesystem" = {
          type = "internal/fs";
          mount-0 = "/";
          format-mounted = "<label-mounted>";
          format-mounted-prefix = "";

          # label-mounted = " %free%";
          label-mounted = "%free% free of %total%";
        };

        "module/i3" = {
          type = "internal/i3";
          pin-workspaces = true;
          index-sort = true;
          label = {

            format = "<label-state> <label-mode>";

            mode = "%mode";
            mode-padding = 2;
            mode-background = "#e60053";

            focused = "%index%";
            focused-foreground = "${colors.foreground}";
            focused-background = "${colors.background-alt}";
            focused-underline = "${colors.primary}";
            focused-padding = 4;

            unfocused = "%index%";
            unfocused-padding = 4;

            visible = "%index%";
            visible-underline = "${colors.foreground-alt}";
            visible-padding = 4;
          };

          # label-separator = "|";
          # label-separator-padding = 2;
          # label-separator-foreground = "#ffb52a";
        };

        "module/spotify" = {
          type = "custom/script";
          tail = true;
          format-prefix = "<prefix-symbol>";
          format = "<label>";
          exec = ''
            ${pkgs.bash}/bin/bash -c "~/.config/polybar/scripts/poly-scroll-spotify.sh"'';
        };

        "module/spotify-prev" = {
          type = "custom/script";
          exec = ''echo "<previous-song-symbol>"'';
          format = "<label>";
          click-left = "playerctl previous -p spotify";
        };

        "module/spotify-play-pause" = {
          type = "custom/ipc";
          hook-0 = ''echo "<playing-symbol>"'';
          hook-1 = ''echo "<pause-symbol>"'';
          initial = 1;
          click-left = "playerctl play-pause - p spotify";
        };

        "module/spotify-next" = {
          type = "custom/script";
          exec = ''echo "next-song-symbol"'';
          format = "<label>";
          click-left = "playerctl next -p spotify";
        };

      };
    };
  };
}
