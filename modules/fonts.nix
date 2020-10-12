{ pkgs, config, ... }: {
  nixpkgs.overlays = [
    (import ./nix-nerd-fonts-overlay/default.nix)
  ]; # should be able to remove soon
  fonts = {
    enableDefaultFonts = true;
    fontconfig.defaultFonts.monospace = [ "Fira Code" ];
    fonts = with pkgs; [ nerd-fonts.firacode ];
    # should be able to remove the overlay method in 20.09
    # fonts = with pkgs; [
    #	nerdfonts.override {
    #		fonts = ["FiraCode"];
    #	}
    #];	
  };
}
