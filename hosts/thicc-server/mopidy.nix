{ config, pkgs, lib, ... }:
let
  # https://github.com/nix-community/home-manager/blob/3c0e381fef63e4fbc6c3292c9e9cbcf479c01794/modules/services/mopidy.nix#L12C3-L20C5
  toMopidyConf = with lib;
    generators.toINI {
      mkKeyValue = generators.mkKeyValueDefault {
        mkValueString = v:
          if isList v then
            "\n  " + concatStringsSep "\n  " v
          else
            generators.mkValueStringDefault { } v;
      } " = ";
    };
in {
  environment.systemPackages = [ pkgs.mopidy ];
  services.mopidy = {
    enable = true;
    extensionPackages = with pkgs; [
      mopidy-spotify
      mopidy-iris
      mopidy-local
      mopidy-scrobbler
      mopidy-mpd
    ];
    configuration = (toMopidyConf {
      mpd = { hostname = "0.0.0.0"; };
      http = { hostname = "0.0.0.0"; };
      file.enabled = false;
      local = { media_dir = "/mnt/fatnas/media/Music"; };
      audio = {
        mixer = "none";
        output =
          "audioresample ! audioconvert ! audio/x-raw,rate=48000,channels=2,format=S16LE ! filesink location=/run/snapserver/mopidy";
      };
      iris = {
        enabled = true;
        snapcast_host = "thicc-server";
      };
    });
  };
  systemd.services.mopidy.after = [ "snapserver.service" ];

  networking.firewall.allowedTCPPorts = [
    #6600 # MPD server
    6680 # MPD server
    # 8000 # Icecast server
  ];

  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  # };
  # https://github.com/fooker/nixcfg/blob/master/machines/toiler/mopidy.nix
  sound.enable = true;
  services.snapserver = {
    enable = true;
    codec = "flac";
    openFirewall = true;
    tcp = {
      enable = true;
      port = 1705;
    };
    http = {
      enable = true;
      port = 1780;
    };
    streams = {
      # pipewire = {
      #     type = "pipe";
      #     location = "/run/snapserver/pipewire";
      #   };
      mopidy = {
        type = "pipe";
        location = "/run/snapserver/mopidy";
        codec = "pcm";
      };
    };
  };
  # systemd.user.services.snapcast-sink = {
  #   wantedBy = [ "pipewire.service" ];
  #   after = [ "pipewire.service" ];
  #   bindsTo = [ "pipewire.service" ];
  #   path = with pkgs; [ gawk pulseaudio ];
  #   script = ''
  #     pactl load-module module-pipe-sink file=/run/snapserver/pipewire sink_name=Snapcast format=s16le rate=48000
  #   '';
  # };
}
