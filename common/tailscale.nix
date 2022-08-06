{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.tailscale ];

  services.tailscale.enable = true;

  networking.firewall.checkReversePath = "loose";

  networking.nameservers = [ "100.100.100.100" "1.1.1.1" "8.8.8.8" ];
  networking.search = [ "johnreillymurray.gmail.com.beta.tailscale.net" ];

}
