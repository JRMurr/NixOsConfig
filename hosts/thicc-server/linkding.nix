{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  nixContainerCfg = config.virtualisation.oci-containers;
  containerCfg = config.myOptions.containers;
  configDir = containerCfg.dataDir;
  containerServiceName = containerName: "${nixContainerCfg.backend}-${containerName}";

in
{
  config = lib.mkIf containerCfg.enable {
    systemd.services."${containerServiceName "linkding"}" = {
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
    };

    services.postgresql = {
      ensureDatabases = [ "linkding" ];
      ensureUsers = [
        {
          name = "linkding";
          ensureDBOwnership = true;
          # ensurePermissions = { "DATABASE \"linkding\"" = "ALL PRIVILEGES"; };
        }
      ];
    };

    age.secrets.linkding-user-pass = {
      file = "${inputs.secrets}/secrets/linkding-user-pass.age";
    };

    virtualisation.oci-containers.containers = {
      "linkding" = {
        autoStart = true;
        image = "sissbruecker/linkding:1.21.0";
        # extraOptions = [ "--pull=always" ];
        # LD_SUPERUSER_PASSWORD
        environmentFiles = [ config.age.secrets.linkding-user-pass.path ];
        environment = {
          "LD_SUPERUSER_NAME" = "jr";
          "LD_DB_ENGINE" = "postgres";
          "LD_DB_DATABASE" = "linkding";
          "LD_DB_USER" = "linkding";
          # "LD_DB_HOST" = "host.docker.internal";
          "LD_DB_HOST" = "/run/postgresql/";
          "LD_SERVER_PORT" = "9090";
        };
        ports = [ "9090:9090" ];
        volumes = [
          "${configDir}/linkding:/etc/linkding/data"
          # "/var/lib/postgresql:/var/lib/postgresql"
          "/run/postgresql/:/run/postgresql/"
        ];
      };

    };
    myCaddy.reverseProxies = {
      "linkding" = {
        serverAliases = [ "links" ];
        upstream = ":9090";
      };
    };

  };
}
