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

      # catppuccin.enable = true;
    };
}
