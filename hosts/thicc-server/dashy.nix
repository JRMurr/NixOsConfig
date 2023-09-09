{ config, pkgs, lib, ... }:
let
  containerCfg = config.myOptions.containers;
  configDir = containerCfg.dataDir;
in {
  config = lib.mkIf containerCfg.enable {
    virtualisation.oci-containers.containers = {
      "dashy" = {
        autoStart = true;
        image = "lissy93/dashy:latest";
        extraOptions = [ "--pull=always" ];
        environment = {
          "NODE_ENV" = "production";
          # TODO: use nix options to get right ids
          "UID" = "1000"; # jr
          "GID" = "131"; # docker
        };
        ports = [ "4000:80" ];
        volumes = [ "${configDir}/dashy/my-config.yml:/app/public/conf.yml" ];
      };

      # "monitoring" = {
      #   autoStart = true;
      #   image = "nicolargo/glances:alpine-3.2.7";
      #   environment = { "GLANCES_OPT" = "-w"; };
      #   ports = [ "61208:61208" ];
      #   volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
      # };
    };
    # myCaddy.reverseProxies = { "glances" = { upstream = ":61208"; }; };
    # services.caddy.virtualHosts = {
    #   "glances.${config.myCaddy.domain}" = {
    #     extraConfig = ''
    #       tls {
    #         dns cloudflare {env.CF_API_TOKEN}
    #       }
    #     '';
    #   };
    # };

  };
}
