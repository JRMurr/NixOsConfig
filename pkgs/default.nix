{ pkgs, ... }:

{
  # caddy with extra plugins
  caddyWithPlugins = pkgs.callPackage ./caddy-with-plugins { };
}
