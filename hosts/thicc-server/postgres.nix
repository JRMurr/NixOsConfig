{ config, pkgs, lib, inputs, ... }:
let tailscaleHostIp = "100.100.60.23"; # TODO: make this a config option
in {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14;
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
      # ipv4
      host  all      all     127.0.0.1/32   trust
      # host  all      all     ${tailscaleHostIp}/32   trust
      # ipv6
      host all       all     ::1/128        trust
    '';
  };

  # TODO: perm issue on nfs share
  # services.postgresqlBackup = {
  #   enable = true;
  #   location = "/mnt/fatnas/serverdata/pg_bak";
  #   backupAll = true;
  # };
}
