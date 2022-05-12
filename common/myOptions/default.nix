{ config, lib, ... }:
with lib; {
  imports = [ ./monitor.nix ];
  options.myOptions.graphics.enable = mkEnableOption "Enable graphics";

  options.myOptions.gestures.enable = mkEnableOption "Enable gestures";
}
