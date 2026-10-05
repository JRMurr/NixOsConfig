{ pkgs, ... }:
let
  tailscale = pkgs.tailscale;
in
{
  # tailscaled runs as root, so it's a system unit that steamos-etc installs, not a
  # Home Manager user service. The CLI is enough in the profile.
  home.packages = [ tailscale ];

  # nixpkgs' own unit, minus the ${PORT} and $FLAGS that NixOS fills in.
  programs.steamos-etc.services.tailscaled = {
    Unit = {
      Description = "Tailscale node agent";
      Documentation = "https://tailscale.com/docs/";
      Wants = [ "network-pre.target" ];
      After = [
        "network-pre.target"
        "NetworkManager.service"
        "systemd-resolved.service"
      ];
    };

    Service = {
      # 41641: NixOS's services.tailscale.port default, as on the other hosts.
      # tailscaled's own default is 0, a random port.
      ExecStart = "${tailscale}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641";
      ExecStopPost = "${tailscale}/bin/tailscaled --cleanup";
      Restart = "on-failure";
      Type = "notify";

      RuntimeDirectory = "tailscale";
      RuntimeDirectoryMode = "0755";
      StateDirectory = "tailscale";
      StateDirectoryMode = "0700";
      CacheDirectory = "tailscale";
      CacheDirectoryMode = "0750";
    };

    Install.WantedBy = [ "multi-user.target" ];
  };
}
