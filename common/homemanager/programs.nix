{ pkgs, inputs, ... }:
let
  nurl = inputs.nurl.packages.${pkgs.system}.default;
  nixd = inputs.nixd.packages.${pkgs.system}.default;
  # nixd does not work on mac yet :(
  # https://github.com/nix-community/nixd/issues/107
  linuxOnly = pkgs.lib.optionals pkgs.stdenv.isLinux [ nixd ];
in {

  home.packages = linuxOnly
    ++ (with pkgs; [ bottom htop cachix nurl dive xclip ]);

}
