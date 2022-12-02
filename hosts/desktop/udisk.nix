{ config, pkgs, ... }: {
  boot.supportedFilesystems = [ "ntfs" ];
  services.udisks2 = { enable = true; };
}
