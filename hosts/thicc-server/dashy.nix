{ config, pkgs, lib, ... }:
let
  containerCfg = config.myOptions.containers;
  configDir = containerCfg.dataDir;
in {
  config = lib.mkIf containerCfg.enable {
    virtualisation.oci-containers.containers = {
      "dashy" = {
        autoStart = true;
        image = "lissy93/dashy:2.1.1";
        environment = {
          "NODE_ENV" = "production";
          # TODO: use nix options to get right ids
          "UID" = "1000"; # jr
          "GID" = "131"; # docker
        };
        ports = [ "80:80" ];
        volumes = [ "${configDir}/dashy/my-config.yml:/app/public/conf.yml" ];
      };

      "monitoring" = {
        autoStart = true;
        image = "nicolargo/glances:alpine-3.2.7";
        environment = { "GLANCES_OPT" = "-w"; };
        ports = [ "61208:61208" "61209:61209" ];
        volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
      };
    };

  };
}
