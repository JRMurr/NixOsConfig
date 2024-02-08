{ pkgs, config, lib, ... }:
let
  myNerdFonts = [ "FiraCode" ];
  polyBarNerdFonts = [
    "Iosevka"
    "FantasqueSansMono"
    "Noto"
    "DroidSansMono"
    "Terminus"
  ]; # https://github.com/adi1090x/polybar-themes#fonts
  polyBarIconFonts = with pkgs; [ material-design-icons material-icons ];

  fontPkgs = with pkgs;
    (
      # valid font names https://github.com/NixOS/nixpkgs/blob/6ba3207643fd27ffa25a172911e3d6825814d155/pkgs/data/fonts/nerdfonts/shas.nix

      polyBarIconFonts
      ++ [ (nerdfonts.override { fonts = myNerdFonts ++ polyBarNerdFonts; }) ]);
in {
  fonts = {
    enableDefaultPackages = true;
    packages = fontPkgs;
    fontconfig.defaultFonts.monospace = [ "FiraCode" ];
  };
}
