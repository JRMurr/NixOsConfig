{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
    version = "2.1.12";
in
{
  services.factorio = {
    package = pkgs.factorio-headless-experimental.overrideAttrs (old: rec {
      src = pkgs.fetchurl {
        name = "factorio-headless_linux_${version}.tar.xz";
        url = "https://factorio.com/get-download/${version}/headless/linux64";
        sha256 = "sha256-iF/wKaQLDt2BXP4fwThF8jJyPaHqj+moPq4RTR7M0/4"; #lib.fakeHash;
      };
    });
    enable = true;
    openFirewall = true;
    port = 7654;
    public = false;
    game-password = "fartbois";
    admins = [ "fatattack" ];
    saveName = "ffff";
  };

}
