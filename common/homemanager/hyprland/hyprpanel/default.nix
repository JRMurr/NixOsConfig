{
  pkgs,
  lib,
  config,
  inputs,
  osConfig,
  ...
}:
let
  gcfg = osConfig.myOptions.graphics;

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

  panelPkgs = pkgs.callPackage ./patched-panel.nix { };

  catCfg = config.catppuccin;

  # builtins.trace "maybe????: ${catCfg.flavor}-${catCfg.accent}" ---- mocha-mauve

  themeFile = "catppuccin_${catCfg.flavor}.json";

  themeJson = builtins.fromJSON (builtins.readFile "${panelPkgs}/share/themes/${themeFile}");

  # toShortcutAttrs :: [a] -> { shortcut1 = a; … }
  toShortcutAttrs =
    list:
    let
      len = builtins.length list;
    in
    if len > 4 then
      builtins.throw "toShortcutAttrs: expected at most 4 values, got ${toString len}"
    else
      builtins.listToAttrs (
        lib.imap1 (idx: val: {
          name = "shortcut${toString idx}";
          value = val;
        }) list
      );

in
{

  age.secrets.weather = {
    file = "${inputs.secrets}/secrets/weather.age";
    path = "/tmp/weather.json";
    symlink = false; # hyprpanel checks if the path is a "regular file"
  };

  programs.hyprpanel = {
    package = panelPkgs;
    enable = true;
    # Configure and theme almost all options from the GUI.
    # See 'https://hyprpanel.com/configuration/settings.html'.

    # can find the keys by looking at the settings dialog src
    # https://github.com/Jas-SinghFSU/HyprPanel/tree/master/src/components/settings/pages/config

    # the patched hyprpanel write to /tmp/hyprpanel-write-attempts on config changes
    settings = lib.mkMerge [
      themeJson
      {
        theme.bar.scaling = 75;
        scalingPriority = "hyprland";
        bar = {
          layouts = lib.listToAttrs (map monitorToBarCfg monitors);
          launcher = {
            icon = "JR";
            # autoDetectIcon = true;
          };
          workspaces = {
            monitorSpecific = true;
            show_numbered = true;
            show_icons = false;
            ignored = "-.*"; # hack to hide the special kitty workspace. It seems to get a negative number?
          };
        };

        menus = {
          clock = {
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

          dashboard = {
            directories = {
              enabled = false;
            };
            stats = {
              enable_gpu = false; # TODO: still doesnt work with cuda support in the pkg
            };

            shortcuts = {
              enabled = true;
              # https://www.nerdfonts.com/cheat-sheet
              left = toShortcutAttrs [
                {
                  icon = "";
                  command = "firefox";
                  tooltip = "Firefox";
                }
                {
                  icon = "";
                  command = "pear-desktop";
                  tooltip = "Youtube Music";
                }
                {
                  icon = "";
                  command = "discord";
                  tooltip = "Discord";
                }
                {
                  icon = "";
                  command = "rofi -show run";
                  tooltip = "Search Apps";
                }
              ];
            };
          };
        };

        # theme.bar.transparent = true;

        # theme.font = {
        #   name = "CaskaydiaCove NF";
        #   size = "16px";
        # };
      }
    ];
  };
}
