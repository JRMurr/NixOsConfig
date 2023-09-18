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
  batExtras = let
    names = [ "batdiff" "batgrep" "batman" "batpipe" "batwatch" "prettybat" ];
  in lib.attrVals names pkgs.bat-extras;
in {

  home.packages = linuxOnly ++ batExtras
    ++ (with pkgs; [ bottom htop cachix nurl dive xclip lastpass-cli ]);

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.exa = lib.mkIf (!onUnStable) {
    enable = true;
    enableAliases = true;
  };
  programs.eza = lib.mkIf onUnStable {
    enable = true;
    enableAliases = true;
  };

  programs.bat = { enable = true; };
}
