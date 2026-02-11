{
  lib,
  osConfig,
  inputs,
  ...
}:
let

  gcfg = osConfig.myOptions.graphics;
in
{
  # imports = [
  #   inputs.catppuccin.homeManagerModules.catppuccin
  # ];
  config = lib.mkIf gcfg.enable {
    # programs.swaylock.enable = false; # seems to be a bug when enabling importing catppuccin

    # lock global options to nixos ones
    catppuccin.enable = osConfig.catppuccin.enable;
    catppuccin.accent = osConfig.catppuccin.accent;
    catppuccin.flavor = osConfig.catppuccin.flavor;
  };
}
