{ config, lib, ... }:
with lib; {
  imports = [ ./monitor.nix ./containers.nix ./tailscale.nix ];
  options.myOptions.graphics.enable = mkEnableOption "Enable graphics";
  options.myOptions.redShift.disable = mkEnableOption "disable redShift";

  options.myOptions.gestures.enable = mkEnableOption "Enable gestures";

  options.myOptions.containers.enable =
    mkEnableOption "Enable nixos-defined containers";

}
