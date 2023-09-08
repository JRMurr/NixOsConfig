{ config, pkgs, lib, ... }:
let
  containerCfg = config.myOptions.containers;
  configDir = containerCfg.dataDir;
  # TODO: Look into blocky instead of pihole, might be easier to configure with nix
  customDnsRules = pkgs.writeText "02-nix-custom.conf" ''
    address=/mine.local/100.100.60.23
    address=/jrnet.win/100.100.60.23
  '';
in {
  config = lib.mkIf containerCfg.enable {

    virtualisation.oci-containers.containers."pihole" = {
      autoStart = true;
      image = "pihole/pihole:2022.07";
      environment = {
        "TZ" = "America/New_York";
        # TODO: make secrets, not a big deal for now
        "WEBPASSWORD" = "I8q22OUb";
      };
      ports = [ "53:53/tcp" "53:53/udp" "81:80" ];
      volumes = [
        "${configDir}/pihole/etc:/etc/pihole"
        "${configDir}/pihole/dnsmasq:/etc/dnsmasq.d"
        "${customDnsRules}:/etc/dnsmasq.d/02-nix-custom.conf"
      ];
      extraOptions =
        [ "--dns" "1.1.1.1" "--dns" "127.0.0.1" "--cap-add=NET_ADMIN" ];
    };
  };
}
