{ config, pkgs, ... }: {
  # Enable sound.
  # sound.enable = true;
  # sound.mediaKeys.enable = true;
  # hardware = {
  #   pulseaudio = {
  #     enable = true;
  #     support32Bit = true;
  #     package = pkgs.pulseaudioFull;
  #   };
  #   # bluetooth.enable = true;
  # };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  environment = { systemPackages = with pkgs; [ pa_applet playerctl ]; };

  home-manager.users.jr = { services.playerctld.enable = true; };
}
