{
  pkgs,
  lib,
  config,
  inputs,
  nixosConfig,
  ...
}:
let
  gcfg = nixosConfig.myOptions.graphics;

  monitors = gcfg.monitors;

  simpleBar = {
    left = [
      "dashboard"
      "workspaces"
    ];
    middle = [ "media" ];
    right = [
      "volume"
      "systray"
      "notifications"
    ];
  };

  mainBar = {
    left = [
      "dashboard"
      "workspaces"
      "windowtitle"
    ];
    middle = [
      "media"
    ];
    right = [
      "volume"
      "network"
      "bluetooth"
      # "battery"
      "systray"
      "clock"
      "notifications"
    ];
  };

  monitorToBarCfg =
    monitorConfig:
    let
      name = monitorConfig.name;
      value = if monitorConfig.primary then mainBar else simpleBar;
    in
    {
      inherit name value;
    };
in
{

  age.secrets.weather = {
    file = "${inputs.secrets}/secrets/weather.age";
    path = "/tmp/weather.json";
    symlink = false; # hyprpanel checks if the path is a "regular file"
  };

  programs.hyprpanel = {
    enable = true;
    # Configure and theme almost all options from the GUI.
    # See 'https://hyprpanel.com/configuration/settings.html'.

    # can find the keys by looking at the settings dialog src
    # https://github.com/Jas-SinghFSU/HyprPanel/tree/master/src/components/settings/pages/config

    settings = {

      bar.layouts = lib.listToAttrs (map monitorToBarCfg monitors);

      bar.launcher.autoDetectIcon = true;
      bar.workspaces.show_icons = true;

      menus.clock = {
        time = {
          military = false;
          hideSeconds = true;
        };

        weather = {
          enabled = true;
          location = "Washington DC";
          key = config.age.secrets.weather.path;
        };
      };

      menus.dashboard.directories.enabled = false;
      menus.dashboard.stats.enable_gpu = false; # TODO:....

      # theme.bar.transparent = true;

      # theme.font = {
      #   name = "CaskaydiaCove NF";
      #   size = "16px";
      # };
    };
  };
}
