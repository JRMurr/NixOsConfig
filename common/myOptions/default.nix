{ config, lib, ... }:
with lib; {
  imports = [ ./monitor.nix ./containers.nix ./tailscale.nix ./users.nix ];

  options.myOptions = {
    graphics.enable = mkEnableOption "Enable graphics";
    redShift.disable = mkEnableOption "disable redShift";

    gestures.enable = mkEnableOption "Enable gestures";

    containers.enable = mkEnableOption "Enable nixos-defined containers";

    networkShares.enable = mkEnableOption "enable network shares";

    musicPrograms.enable = mkEnableOption "enable network shares";
  };
}
