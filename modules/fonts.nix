{ pkgs, config, ... }: {
  fonts = {
    enableDefaultFonts = true;
    fontconfig.defaultFonts.monospace = [ "Fira Code" ];
    fonts = with pkgs;
      [ (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; }) ];
  };
}
