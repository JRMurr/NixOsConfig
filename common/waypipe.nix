{
  pkgs,
  config,
  lib,
  ...
}:
{
  # System-wide so `waypipe ssh` from the Frame finds `waypipe server` on PATH.
  # xwayland-satellite backs `waypipe --xwls` for X11 apps.
  config = lib.mkIf config.myOptions.waypipe.enable {
    environment.systemPackages = [
      pkgs.waypipe
      pkgs.xwayland-satellite
    ];
  };
}
