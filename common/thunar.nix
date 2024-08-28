{
  config,
  pkgs,
  lib,
  ...
}:
let
  gcfg = config.myOptions.graphics;
in
{
  # https://nixos.wiki/wiki/Thunar
  config = lib.mkIf gcfg.enable {
    programs = {
      thunar = {
        enable = true;
        plugins = with pkgs.xfce; [
          thunar-archive-plugin
          thunar-volman
        ];
      };
      xfconf.enable = true;
    };
    services.gvfs.enable = true; # Mount, trash, and other functionalities
    services.tumbler.enable = true; # Thumbnail support for images
  };
}
