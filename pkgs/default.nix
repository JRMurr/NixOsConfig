{
  pkgs ? (import ../pinned_from_flake.nix { }).pkgs,
  ...
}:

{
  ccusage = pkgs.callPackage ./ccusage.nix { };

  glance = pkgs.callPackage ./glance.nix { buildGoModule = pkgs.buildGo122Module; };

  happy-server = pkgs.callPackage ./happy-server.nix { };

  polybar-spotify = pkgs.callPackage ./polybar-spotify { player = "YoutubeMusic"; };
}
