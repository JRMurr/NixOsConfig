{ pkgs
, config
, lib
, ...
}:
let
  myNerdFonts = [ "fira-code" ];
  polyBarNerdFonts = [
    "iosevka"
    "fantasque-sans-mono"
    "noto"
    "droid-sans-mono"
    # "Terminus"
  ]; # https://github.com/adi1090x/polybar-themes#fonts

  nerdFonts = builtins.map (font: builtins.getAttr font pkgs.nerd-fonts) (myNerdFonts ++ polyBarNerdFonts);

  polyBarIconFonts = with pkgs;
    [
      material-design-icons
      material-icons
    ];

  fontPkgs =
    with pkgs;
    (
      # valid font names https://github.com/NixOS/nixpkgs/blob/6ba3207643fd27ffa25a172911e3d6825814d155/pkgs/data/fonts/nerdfonts/shas.nix

      polyBarIconFonts ++ nerdFonts
    );
in
{
  fonts = {
    enableDefaultPackages = true;
    packages = fontPkgs;
    fontconfig.defaultFonts.monospace = [ "FiraCode" ];
  };
}
