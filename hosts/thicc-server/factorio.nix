{ config, pkgs, lib, inputs, ... }:
let
in {
  services.factorio = {
    enable = true;
    openFirewall = true;
    port = 7654;
    public = false;
    game-password = "fartbois";
    admins = [ "fatattack" ];
  };

}
