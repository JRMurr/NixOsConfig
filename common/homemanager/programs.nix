{ pkgs, inputs, ... }:
let
  nurl = inputs.nurl.packages.${pkgs.system}.default;
  # nurl
in { home.packages = with pkgs; [ bottom htop cachix ]; }
