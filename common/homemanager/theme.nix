{
  osConfig,
  inputs,
  ...
}:
{
  # imports = [
  #   inputs.catppuccin.homeManagerModules.catppuccin
  # ];
  # programs.swaylock.enable = false; # seems to be a bug when enabling importing catppuccin

  # Lock global options to the nixos ones. Deliberately not gated on
  # myOptions.graphics.enable -- the HM module emits the same `autoEnable` warning
  # as the system one, so the option has to be defined on headless hosts too.
  # See common/theme.nix.
  config = {
    catppuccin.enable = osConfig.catppuccin.enable;
    catppuccin.autoEnable = osConfig.catppuccin.autoEnable;
    catppuccin.accent = osConfig.catppuccin.accent;
    catppuccin.flavor = osConfig.catppuccin.flavor;
  };
}
