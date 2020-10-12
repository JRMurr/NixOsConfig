{ pkgs, lib, config, ... }:

let
in {
  home-manager.users.jr = {
    services.kanshi = { enable = true; };

    wayland.windowManager.sway = {
      enable = true;

    };
  };
}
