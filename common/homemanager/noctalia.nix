{ pkgs, ... }:
let
  # https://docs.noctalia.dev/getting-started/nixos/#noctalia-settings
  diffNoctalia = pkgs.writeShellApplication {
    name = "diff-noctalia";

    checkPhase = "";
    runtimeInputs = [
      pkgs.colordiff
      pkgs.jq
    ];

    text = ''
      diff -u <(jq -S . ~/.config/noctalia/settings.json) <(jq -S . ~/.config/noctalia/gui-settings.json) | colordiff
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
      # configure noctalia here
      bar = {
        # density = "compact";
        position = "top";
        # showCapsule = false;
        widgets = {
          left = [
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
            {
              id = "WiFi";
            }
            {
              id = "Bluetooth";
            }
          ];
          center = [
            {
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "index";
            }
          ];
          right = [
            {
              alwaysShowPercentage = false;
              id = "Battery";
              warningThreshold = 30;
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
      # colorSchemes.predefinedScheme = "Monochrome";
      general = {
        # avatarImage = "/home/drfoobar/.face";
        radiusRatio = 0.2;
      };
      # location = {
      #   monthBeforeDay = true;
      #   name = "Marseille, France";
      # };
    };
    # this may also be a string or a path to a JSON file.
  };
}
