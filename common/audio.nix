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

      # https://old.reddit.com/r/NixOS/comments/1je2ebl/nixos_tips_your_headsets_handsfree_mode_is_gone/
      # https://nixos.wiki/wiki/PipeWire#Bluetooth_Configuration
      # wireplumber.extraConfig.bluetoothEnhancements = {
      #   # https://www.whathifi.com/advice/what-are-the-best-bluetooth-codecs-aptx-aac-ldac-and-more-explained
      #   # https://www.reddit.com/r/bluetooth/comments/z2hj48/sbcxq_vs_ldac/
      #   "monitor.bluez.properties" = {
      #     # "bluez5.enable-sbc-xq" = true;
      #     # this is to enable some headsets' Handsfree mode
      #     # "bluez5.enable-msbc" = true;
      #     "bluez5.enable-hw-volume" = true;
      #     # "bluez5.roles" = [
      #     #   "hsp_hs"
      #     #   "hsp_ag"
      #     #   "hfp_hf"
      #     #   "hfp_ag"
      #     # ];
      #   };
      # };
    };

    environment.systemPackages = [
      pkgs.pavucontrol
      pkgs.snapcast
    ];

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
