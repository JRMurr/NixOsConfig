{
  pkgs,
  lib,
  inputs,
  nixosConfig,
  ...
}:
let
  gcfg = nixosConfig.myOptions.graphics;

  # sysVersion = nixosConfig.system.nixos.release;
  # onUnStable = lib.versionAtLeast sysVersion "23.11";
  # getFromInput = name: inputs.${name}.packages.${pkgs.system}.default;
  nurl = inputs.nurl.packages.${pkgs.system}.default;
  nixd = inputs.nixd.packages.${pkgs.system}.default;
  nil = inputs.nil.packages.${pkgs.system}.default;

  ghostty = inputs.ghostty.packages.${pkgs.system}.default;

  # nurl = getFromInput "nurl";
  # nixd = getFromInput "nurl";
  # nil = getFromInput "nurl";

  # nixd does not work on mac yet :(
  # https://github.com/nix-community/nixd/issues/107
  linuxOnly = pkgs.lib.optionals pkgs.stdenv.isLinux [
    nixd
    nil
  ];

  graphical = pkgs.lib.optionals gcfg.enable [
    # ghostty
  ];

  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/tools/misc/bat-extras/default.nix#L142
  batExtras =
    let
      names = [
        "batdiff"
        "batgrep"
        "batman"
        "batpipe"
        "batwatch"
        "prettybat"
      ];
    in
    lib.attrVals names pkgs.bat-extras;

in
{
  home.packages =
    linuxOnly
    ++ graphical
    ++
      # batExtras ++
      (with pkgs; [
        bottom
        htop
        cachix
        nurl
        dive
        xclip
        # lastpass-cli
        # tailspin
        ouch # file decompresser
        bacon # rust background checker
        ripgrep
        youtube-music
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

    bat = {
      enable = true;
    };

    eza = {
      enable = true;
      enableFishIntegration = true;
    };
  };

}
