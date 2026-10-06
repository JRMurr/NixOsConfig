{
  pkgs,
  config,
  lib,
  ...
}:
{
  # System-wide so `waypipe ssh` from the Frame finds `waypipe server` on PATH.
  config = lib.mkIf config.myOptions.waypipe.enable {
    environment.systemPackages = [ pkgs.waypipe ];
  };
}
