{ pkgs, lib, config, nixosConfig, ... }:
# TODO: add https://github.com/PrayagS/polybar-spotify
with lib;

let
  gcfg = nixosConfig.myOptions.graphics;
  monitors = gcfg.monitors;
  # TODO: make lib func for easy group by to single value?
  monitorsByName = attrsets.mapAttrs (name: value: head value)
    (lists.groupBy (x: x.name) monitors);
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
  simpleBar = commonBarOpts // { modules-right = "time"; };
  mainBar = commonBarOpts // {
    modules-right = "filesystem eth-speed ram cpu date time "
      + (if nixosConfig.networking.hostName == "framework" then
        "battery"
      else
        "");
    tray-position = "right";
    dpi = nixosConfig.services.xserver.dpi;
  };

  monitorToBarCfg = monitorConfig:
    if monitorConfig.primary then
      mainBar // { monitor = "${monitorConfig.name}"; }
    else
      simpleBar // { monitor = "${monitorConfig.name}"; };

  bars = attrsets.mapAttrs' (name: monitorConfig:
    attrsets.nameValuePair ("bar/${monitorConfig.name}")
    (monitorToBarCfg monitorConfig)) monitorsByName;

  monitorToStartScript = monitorConfig:
    if monitorConfig.enable then
      "polybar --reload ${monitorConfig.name} & disown;"
    else
      "";
in {
  config = lib.mkIf gcfg.enable {
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
        script = lib.concatMapStringsSep "\n" monitorToStartScript monitors;
        settings = bars //  {

          # barConf = commonBarOpts // {
          #   # modules-center = "title";
          #   modules-right = "eth-speed ram cpu date time";
          # };

          "module/battery" = {
            type = "internal/battery";
            # https://github.com/polybar/polybar/wiki/Module%3A-battery#basic-settings
            battery = "BAT1";
            adapter = "ACAD";
          };

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
            time = "%I:%M";
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
  };
}
