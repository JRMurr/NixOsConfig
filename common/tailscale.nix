{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.tailscale ];

  services.tailscale.enable = true;

  networking.firewall.checkReversePath = "loose";

  #   networking.nameservers =
  #     [ "100.100.100.100" "192.168.1.160" ];
  #   networking.search = [ "example.com.beta.tailscale.net" ];

}
