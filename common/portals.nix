{ pkgs, ... }:
{
  xdg.portal = {
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    enable = true;

    config = {
      common.default = "*";
    };
  };

  # https://github.com/flatpak/xdg-desktop-portal-gtk/issues/440#issuecomment-1900520919
  # https://github.com/NixOS/nixpkgs/issues/189851
  systemd.user.services."wait-for-full-path" = {
    description = "wait for systemd units to have full PATH";
    wantedBy = [ "xdg-desktop-portal.service" ];
    before = [ "xdg-desktop-portal.service" ];
    path = with pkgs; [
      systemd
      coreutils
      gnugrep
    ];
    script = ''
      ispresent () {
        systemctl --user show-environment | grep -E '^PATH=.*/.nix-profile/bin'
      }
      while ! ispresent; do
        sleep 0.1;
      done
    '';
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "60";
    };
  };
}
