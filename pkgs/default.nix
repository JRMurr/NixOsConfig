{
  pkgs ? (import ../pinned_from_flake.nix { }).pkgs,
  ...
}:

{
  ccusage = pkgs.callPackage ./ccusage.nix { };

  glance = pkgs.callPackage ./glance.nix { buildGoModule = pkgs.buildGo122Module; };

  polybar-spotify = pkgs.callPackage ./polybar-spotify { player = "YoutubeMusic"; };
}
