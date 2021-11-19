{ pkgs, lib, config, ... }: {
  environment.variables.XCURSOR_SIZE = "10";
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver = {
    enable = true;
    dpi = 100;
    # screenSection = ''
    #   Option "metamodes" "nvidia-auto-select +0+0 { ForceCompositionPipeline = On }"
    # '';
    displayManager.lightdm = {
      enable = true;
      greeters.gtk.cursorTheme = {
        package = pkgs.gnome3.adwaita-icon-theme;
        size = 10;
      };
    };
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "jr";
    };
    #     displayManager.sessionCommands = ''${pkgs.xlibs.xrandr}/bin/xrandr --fb 4137x4080 --output DP-3 --gamma 1.0:1.0:1.0 --mode 3840x2160 --pos 297x0 --rate 60.00 --reflect normal --rotate normal --output DP-4 --gamma 1.0:1.0:1.0 --mode 1920x1080 --pos 0x2160 --rate 60.00 --reflect normal --rotate left
    # xrandr --fb 4137x4080 --output DP-1 --gamma 1.0:1.0:1.0 --mode 2560x1440 --pos 1080x2160 --primary --rate 120 --reflect normal --rotate normal'';
    desktopManager.xterm.enable = false;
    desktopManager = {
      wallpaper = {
        mode = "scale";
        combineScreens = true;
      };
    };
    windowManager.i3.enable = true;
    displayManager.defaultSession = "none+i3";
  };
}
