{
  pkgs,
  lib,
  osConfig,
  inputs,
  ...
}:
let
  gcfg = osConfig.myOptions.graphics;

  # Ghostty isn't in nixpkgs on this channel (and moves fast), so we pull it
  # straight from the upstream flake input. See common/homemanager/programs.nix
  # for the same pattern with the other flake-sourced tools.
  ghostty = inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  # Ghostty is Linux/macOS only here; gate it the same way kitty.nix does.
  config = lib.mkIf (pkgs.stdenv.isDarwin || gcfg.enable) {
    programs.ghostty = {
      enable = true;
      package = ghostty;

      enableFishIntegration = true;
      enableBashIntegration = true;

      settings = {
        font-family = "FiraCode Nerd Font";
        command = "fish";

        keybind = [
          "shift+enter=text:\\n"
        ];
      };
    };
  };
}
