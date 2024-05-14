{ pkgs ? (import ../pinned_from_flake.nix { }).pkgs, ... }:

{
  # caddy with extra plugins
  caddyWithPlugins = pkgs.callPackage ./caddy-with-plugins { };

  glance = pkgs.callPackage ./glance.nix {
    buildGoModule = pkgs.buildGo122Module;
  };
}
