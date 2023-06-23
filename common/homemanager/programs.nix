{ pkgs, inputs, ... }:
let
  nurl = inputs.nurl.packages.${pkgs.system}.default;
  nixd = inputs.nixd.packages.${pkgs.system}.default;
in { home.packages = with pkgs; [ bottom htop cachix nixd nurl ]; }
