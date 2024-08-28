{
  config,
  pkgs,
  lib,
  ...
}:
let
  containerCfg = config.myOptions.containers;
  configDir = containerCfg.dataDir;
in
{
  config = lib.mkIf containerCfg.enable {
    virtualisation.oci-containers.containers."it-tools" = {
      autoStart = true;
      image = "corentinth/it-tools:latest";
      extraOptions = [ "--pull=always" ];
      ports = [ "8070:80" ];
    };
    myCaddy.reverseProxies = {
      "tools" = {
        upstream = "thicc-server:8070";
      };
    };
  };
}
