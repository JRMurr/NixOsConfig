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
      catppuccin.enable = true;
    };
}
 