{ config, pkgs, lib, ... }:
let
  containerCfg = config.myOptions.containers;
  configDir = containerCfg.dataDir;
in {
  config = lib.mkIf containerCfg.enable {

    virtualisation.oci-containers.containers."pihole" = {
      autoStart = true;
      image = "pihole/pihole:latest";
      environment = {
        "TZ" = "America/New_York";
        # TODO: make secrets, not a big deal for now
        "WEBPASSWORD" = "I8q22OUb";
      };
      ports = [ "53:53/tcp" "53:53/udp" "80:80" ];
      volumes = [
        "${configDir}/pihole/etc:/etc/pihole"
        "${configDir}/pihole/dnsmasq:/etc/dnsmasq.d"
      ];
      extraOptions =
        [ "--dns" "1.1.1.1" "--dns" "127.0.0.1" "--cap-add=NET_ADMIN" ];
    };
  };
}
