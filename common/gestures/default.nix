{ config, pkgs, lib, ... }:
let gestureConfig = config.myOptions.gestures;
in {
  config = lib.mkIf gestureConfig.enable {
    environment.systemPackages = with pkgs; [ fusuma ];
    home-manager.users.jr = {
      xdg.configFile."fusuma" = {
        text = ''
          swipe:
              4:
                  left:
                      command: "i3-msg 'workspace next'"
                  right:
                      command: "i3-msg 'workspace prev'"
        '';
        target = "fusuma/config.yml";
      };
    };
  };
}
