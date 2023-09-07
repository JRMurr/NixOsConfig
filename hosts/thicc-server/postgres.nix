{ config, pkgs, lib, inputs, ... }: {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
      # ipv4
      host  all      all     127.0.0.1/32   trust
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
