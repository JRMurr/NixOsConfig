{ config, lib, ... }:
with lib; {
  imports = [ ./monitor.nix ./containers.nix ];
  options.myOptions.graphics.enable = mkEnableOption "Enable graphics";

  options.myOptions.gestures.enable = mkEnableOption "Enable gestures";

  options.myOptions.containers.enable =
    mkEnableOption "Enable nixos-defined containers";

}
