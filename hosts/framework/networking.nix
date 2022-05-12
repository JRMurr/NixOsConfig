{ config, pkgs, ... }: {
  networking = {
    hostName = "nixos-john";
    networkmanager.enable = true;
    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    useDHCP = false;
    interfaces.w1p170s0.useDHCP = true;

    firewall.allowedTCPPorts = [ 57621 ]; # for spotify
  };

  programs.nm-applet.enable = true;
}
