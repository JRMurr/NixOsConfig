{ pkgs, inputs, ... }:
let
  # getFromInput = name: inputs.${name}.packages.${pkgs.system}.default;
  nurl = inputs.nurl.packages.${pkgs.system}.default;
  nixd = inputs.nixd.packages.${pkgs.system}.default;
  nil = inputs.nil.packages.${pkgs.system}.default;
  # nurl = getFromInput "nurl";
  # nixd = getFromInput "nurl";
  # nil = getFromInput "nurl";

  # nixd does not work on mac yet :(
  # https://github.com/nix-community/nixd/issues/107
  linuxOnly = pkgs.lib.optionals pkgs.stdenv.isLinux [ nixd nil ];
in {

  home.packages = linuxOnly
    ++ (with pkgs; [ bottom htop cachix nurl dive xclip ]);

}
