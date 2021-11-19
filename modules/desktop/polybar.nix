{ pkgs, lib, config, ... }:
let
  # TODO: make these declared in module.nix and use them in i3, polybar, and autorandr
  mainMonitor = "DP-4";
  topMonitor = "HDMI-0";
  sideMonitor = "USB-C-0";
in {
  # try to use stuff from https://github.com/adi1090x/polybar-themes
  # this looks good https://github.com/adi1090x/polybar-themes/tree/master/simple/material
  # environment.systemPackages = [ pkgs.pywal ];
  home-manager.users.jr = {
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
            foreground = "#FFFFFF";
            foreground-alt = "#8F8F8F";
            module-fg = "#1F1F1F";
            primary = "#ffb300";
            secondary = "#E53935";
            alternate = "#7cb342";
          };

          formatting = {
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

          barConf = formatting // {
            bottom = true;
            enable-ipc = true;

            modules-left = "i3";
            modules-center = "title";
            modules-right = "eth-speed ram cpu date time";
          };

          "bar/main" = barConf // { monitor = "${mainMonitor}"; };
          "bar/side" = barConf // { monitor = "${sideMonitor}"; };
          "bar/top" = barConf // { monitor = "${topMonitor}"; };

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

          "module/i3" = {
            type = "internal/i3";
            pin-workspaces = true;
          };

        };
      };
    };
  };
}
