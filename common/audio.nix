{ config, pkgs, lib, ... }:
let gcfg = config.myOptions.graphics;
in {
  # TODO: for now if graphics are off audio is probably off
  config = lib.mkIf gcfg.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

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
    environment.systemPackages = [ pkgs.pavucontrol pkgs.snapcast ];

    # TODO: make configurable and look into options
    # systemd.user.services.snapclient-local = {
    #   wantedBy = [ "pipewire.service" ];
    #   after = [ "pipewire.service" ];
    #   serviceConfig = {
    #     ExecStart = "${pkgs.snapcast}/bin/snapclient -h thicc-server";
    #   };
    # };
  };

}
