{ pkgs, config, ... }: {
  services.gvfs.enable = true;
  environment.systemPackages = with pkgs;
    [
      lxqt.lxqt-policykit
    ]; # provides a default authentification client for policykitcle
  fileSystems."/mnt/games" = {
    device = "//192.168.1.151/games";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts =
        "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      uid = "1000";
      gid = "100"; # users
    in [
      "${automount_opts},credentials=/etc/nixos/secrets/smb,uid=${uid},gid=${gid}"
    ];
  };
}