{ pkgs, config, ... }: {
  fileSystems."/mnt/games" = {
    device = "//192.168.1.151/games";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts =
        "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      uid = "1000";
      gid = "1"; # wheel
    in [
      "${automount_opts},credentials=/etc/nixos/secrets/smb,uid=${uid},gid=${gid}"
    ];
  };
}
