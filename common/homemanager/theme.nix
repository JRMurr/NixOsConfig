{ lib, nixosConfig, inputs, ... }:
let

  gcfg = nixosConfig.myOptions.graphics;
in
{
  # imports = [
  #   inputs.catppuccin.homeManagerModules.catppuccin 
  # ];
  config = lib.mkIf gcfg.enable
    {
      programs.swaylock.enable = false; # seems to be a bug when enabling importing catppuccin

      # lock global options to nixos ones
      catppuccin.enable = nixosConfig.catppuccin.enable;
      catppuccin.accent = nixosConfig.catppuccin.accent;
      catppuccin.flavor = nixosConfig.catppuccin.flavor;
    };
}
 