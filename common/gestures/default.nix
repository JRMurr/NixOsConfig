{ config, pkgs, lib, ... }:
let gestureConfig = config.myOptions.gestures;
in {
  config = lib.mkIf gestureConfig.enable {
    environment.systemPackages = with pkgs; [ fusuma ];
    home-manager.users.jr = {
      xdg.configFile."fusuma" = {
        source = ./config.yml;
        target = "fusuma/config.yml";
      };
    };
  };
}
