{ pkgs, lib, inputs, nixosConfig, ... }:
let
  sysVersion = nixosConfig.system.nixos.release;
  onUnStable = lib.versionAtLeast sysVersion "23.11";
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

  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/tools/misc/bat-extras/default.nix#L142
  batExtras =
    let
      names = [ "batdiff" "batgrep" "batman" "batpipe" "batwatch" "prettybat" ];
    in
    lib.attrVals names pkgs.bat-extras;

  exaConf =
    let
      opts = {
        enable = true;
        enableAliases = true;
      };
    in
    if onUnStable then { eza = opts; } else { exa = opts; };

in
{

  home.packages = linuxOnly ++ batExtras ++ (with pkgs; [
    bottom
    htop
    cachix
    nurl
    dive
    xclip
    lastpass-cli
    tailspin
    ouch # file decompresser
  ]);

  programs = {
    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    fzf = {
      enable = true;
      enableFishIntegration = true;
    };

    bat = { enable = true; };
  } // exaConf;

}
