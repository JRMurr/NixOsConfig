{ osConfig, ... }:
{
  # Copies the system configuration into the home-manager options declared in
  # ./myOptions.nix. Only ./default.nix imports this, so hosts/frame (standalone,
  # no NixOS config) never evaluates it.
  myOptions = {
    graphics.enable = osConfig.myOptions.graphics.enable;
    llm.skills = osConfig.myOptions.llm.skills;
  };

  # Locked to the system values. Deliberately not gated on graphics.enable -- the
  # HM module emits the same `autoEnable` warning as the system one, so the
  # option has to be defined on headless hosts too. See common/theme.nix.
  catppuccin = {
    inherit (osConfig.catppuccin)
      enable
      autoEnable
      accent
      flavor
      ;
  };
}
