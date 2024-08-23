{
  pkgs,
  lib,
  config,
  nixosConfig,
  ...
}:
# TODO: look into https://github.com/polybar/polybar-scripts
with lib;

let
  gcfg = nixosConfig.myOptions.graphics;
  themeCfg = nixosConfig.myOptions.theme;

  baseColors = themeCfg.colors;

  monitors = gcfg.monitors;
  # TODO: make lib func for easy group by to single value?
  monitorsByName = attrsets.mapAttrs (name: value: head value) (lists.groupBy (x: x.name) monitors);
  # colors = {
  #   background = "#1F1F1F";
  #   background-alt = "#3f3f3f";
  #   foreground = "#FFFFFF";
  #   foreground-alt = "#8F8F8F";
  #   module-fg = "#1F1F1F";
  #   primary = "#ffb300";
  #   secondary = "#E53935";
  #   alternate = "#7cb342";
  # };
  # https://github.com/Trollwut/dotfiles-polybar-dracula/blob/63a650f5b26b87930a822391704cdec22fe1faa8/polybar/.config/polybar/config#L35
  # colors = rec {
  #   fg = "#f8f8f2";
  #   text-fg = "${fg}";
  #   bg = "#282a36";
  #   base-bg = bg; # ${self.bg:#dd282a36}
  #   text-bg = bg;
  #   selection = "#44475a";
  #   comment = "#6272a4";
  #   glyph-bg = comment;
  #   module-bg = comment;
  #   cyan = "#8be9fd";
  #   green = "#50fa7b";
  #   orange = "#ffb86c";
  #   pink = "#ff79c6";
  #   purple = "#bd93f9";
  #   red = "#ff5555";
  #   white = "#f8f8f2";
  #   yellow = "#f1fa8c";

  #   #aliases so i dont change the actual formatting below
  #   background = bg;
  #   foreground = fg;
  #   primary = pink;
  #   background-alt = module-bg;
  # };

  # https://github.com/catppuccin/catppuccin/blob/main/docs/style-guide.md
  colors = baseColors // {
    primary = baseColors.accent;
  };

  formatting = {
    fixed-center = true;
    background = "${colors.background}";
    foreground = "${colors.text}";
    line-size = 2;
    line-color = "${colors.primary}";
    border-size = 3;
    border-color = "${colors.background}";
    tray-background = "${colors.background}";
    module-margin-left = 1;
    module-margin-right = 1;
    # fc-match "Fira Code Nerd Font:style=medium"  
    font = [
      "Fira Code Nerd Font:style=medium:size=11;3"
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
  simpleBar = commonBarOpts // {
    modules-right = "time";
  };
  mainBar = commonBarOpts // {
    # eth-speed
    modules-right =
      "filesystem ram cpu date time "
      + (if nixosConfig.networking.hostName == "framework" then "battery" else "");
    tray-position = "right";

    modules-center = "spotify-prev spotify spotify-next";
  };

  monitorToBarCfg =
    monitorConfig:
    let
      barCfg = {
        monitor = "${monitorConfig.name}";
        dpi =
          if monitorConfig.dpi == null then
            (if nixosConfig.services.xserver.dpi == null then 100 else nixosConfig.services.xserver.dpi)
          else
            monitorConfig.dpi;
      };
      inheritedCfg = if monitorConfig.primary then mainBar else simpleBar;
      baseConfig = inheritedCfg // barCfg;
    in
    # TODO: this does shallow merge
    monitorConfig.extraBarOpts // baseConfig;

  bars = attrsets.mapAttrs' (
    name: monitorConfig:
    attrsets.nameValuePair ("bar/${monitorConfig.name}") (monitorToBarCfg monitorConfig)
  ) monitorsByName;

  monitorToStartScript =
    monitorConfig:
    if monitorConfig.enable then "polybar --reload ${monitorConfig.name} & disown;" else "";

  spotifyPkg = pkgs.callPackage ./spotify { };

  dependentPackages = with pkgs; [
    zscroll
    playerctl
    spotifyPkg
  ];
  playerctlPath = "${pkgs.playerctl}/bin/playerctl";
in
{
  config = lib.mkIf gcfg.enable {
    # try to use stuff from https://github.com/adi1090x/polybar-themes
    # this looks good https://github.com/adi1090x/polybar-themes/tree/master/simple/material
    # environment.systemPackages = " pkgs.pywal " {;

    home.packages = dependentPackages;
    services.playerctld.enable = true;

    # add to polybar path
    # systemd.user.services.polybar.Service.Environment = lib.mkForce
    #   "PATH=${pkgs.polybarFull}/bin:${
    #     lib.makeBinPath dependentPackages
    #   }:/run/wrappers/bin";

    services = {
      polybar = {
        enable = true;
        package = pkgs.polybarFull;
        script =
          # ''PATH="${lib.makeBinPath dependentPackages}${"PATH:+:"}$PATH\n''
          # ++ 
          lib.concatMapStringsSep "\n" monitorToStartScript monitors;
        settings = bars // {

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
            format-prefix = "󰻠 ";
            format = "<label>";
            label = "%percentage:02%%";
          };

          "module/ram" = {
            type = "internal/memory";
            interval = 3;
            format-prefix = "󰍛 ";
            format = "<label>";
            label = "%gb_free%/%gb_total%";
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
            format-mounted-prefix = "󰆼 ";

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
              # focused-foreground = "${colors.foreground}";
              focused-background = "${colors.background-alt}";
              focused-underline = "${colors.primary}";
              focused-padding = 2;

              unfocused = "%index%";
              unfocused-padding = 2;

              visible = "%index%";
              # visible-underline = "${colors.foreground-alt}";
              visible-padding = 2;
            };

            # label-separator = "|";
            # label-separator-padding = 2;
            # label-separator-foreground = "#ffb52a";
          };

          "module/spotify" = {
            type = "custom/script";
            tail = true;
            # format-prefix = " ";
            # label = "%{u#1db954}%{+u}%output%";
            format = "<label>";
            # label-active-font = 2;
            label-minlen = 31;
            label-alignment = "center";
            exec = "${spotifyPkg}/bin/scroll_spotify_status";
            click-left = "${playerctlPath} play-pause -p spotify";
          };

          "module/spotify-prev" = {
            type = "custom/script";
            exec = ''echo "󰒫"'';
            format = "<label>";
            click-left = "${playerctlPath} previous -p spotify";
          };

          "module/spotify-play-pause" = {
            type = "custom/ipc";
            hook-0 = ''echo "󰐊"'';
            hook-1 = ''echo "󰏤"'';
            initial = 1;
            click-left = "${playerctlPath} play-pause -p spotify";
          };

          "module/spotify-next" = {
            type = "custom/script";
            exec = ''echo "󰒬 "'';
            format = "<label>";
            click-left = "${playerctlPath} next -p spotify";
          };

        };
      };
    };
  };
}
