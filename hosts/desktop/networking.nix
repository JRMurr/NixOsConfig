{ config, pkgs, ... }:
{
  networking = {
    hostName = "desktop";
    networkmanager.enable = true;
    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    useDHCP = false;
    interfaces.enp10s0.useDHCP = true;
    interfaces.wlp8s0.useDHCP = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [
        57621 # for spotify
        8050 # for protohackers
        5173 # sveltekit local app
      ];
    };
  };

  programs.nm-applet.enable = true;
}
