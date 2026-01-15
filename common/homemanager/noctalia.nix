{ pkgs, ... }:
let
  # https://docs.noctalia.dev/getting-started/nixos/#noctalia-settings
  diffNoctalia = pkgs.writeShellApplication {
    name = "diff-noctalia";

    checkPhase = "";
    runtimeInputs = [
      # pkgs.colordiff
      # pkgs.jq
      pkgs.json-diff
    ];

    #       diff -u <(jq -S . ~/.config/noctalia/settings.json) <(jq -S . ~/.config/noctalia/gui-settings.json) | colordiff

    text = ''
      json-diff  ~/.config/noctalia/settings.json ~/.config/noctalia/gui-settings.json
    '';
  };

in
{
  programs.fish.functions = {
    diffNoc = "${pkgs.lib.getExe diffNoctalia}";
  };
  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;

    settings = {
      ui = {
        fontDefault = "FiraCode Nerd Font";
        fontFixed = "FiraCode Nerd Font Mono";
      };
      bar = {
        # density = "compact";
        position = "top";
        useSeparateOpacity = true;
        backgroundOpacity = 0.36;
        # showCapsule = false;
        widgets = {
          left = [
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
            {
              id = "Workspace";
              hideUnoccupied = false;
              labelMode = "index";
            }

          ];
          center = [
            {
              id = "MediaMini";
            }
          ];
          right = [
            {
              id = "WiFi";
            }
            {
              id = "Bluetooth";
            }
            {
              alwaysShowPercentage = false;
              id = "Battery";
              warningThreshold = 30;
            }
            {
              id = "Tray";
              drawerEnabled = false;
            }
            {
              formatHorizontal = "HH:mm";
              formatVertical = "HH mm";
              id = "Clock";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
          ];
        };
      };
      colorSchemes.predefinedScheme = "Catppuccin";
      general = {
        # avatarImage = "/home/drfoobar/.face";
        radiusRatio = 0.2;
      };
      location = {
        monthBeforeDay = true;
        name = "DC";
        useFahrenheit = true;
      };
    };
    # this may also be a string or a path to a JSON file.
  };
}
