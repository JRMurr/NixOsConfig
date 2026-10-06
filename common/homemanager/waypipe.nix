{
  pkgs,
  config,
  lib,
  ...
}:
{
  # For standalone hosts (the Frame), the client end: `waypipe ssh jr@desktop
  # firefox` shows the desktop's firefox here. NixOS hosts use common/waypipe.nix.
  config = lib.mkIf config.myOptions.waypipe.enable {
    home.packages = [ pkgs.waypipe ];

    # `wpssh jr@framework <app>`; --xwls also forwards X11 apps.
    home.shellAliases.wpssh = "waypipe --xwls ssh";
  };
}
