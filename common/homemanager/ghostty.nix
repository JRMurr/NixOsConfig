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

  isSelected = osConfig.myOptions.terminal == "ghostty";
in
{
  # Ghostty is Linux/macOS only here; gate it the same way kitty.nix does, and
  # only build it when it's the selected terminal -- it comes from a flake input
  # rather than the binary cache, so an unused ghostty is a full source build.
  config = lib.mkIf ((pkgs.stdenv.isDarwin || gcfg.enable) && isSelected) {
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
