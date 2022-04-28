{ config, pkgs, lib, ... }:
let gcfg = config.myOptions.graphics;
in {
  # TODO: for now if graphics are off audio is probably off
  config = lib.mkIf gcfg.enable {
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
    environment.systemPackages = [ pkgs.pavucontrol ];
  };

}
