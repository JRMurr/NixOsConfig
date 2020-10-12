{ pkgs, config, ... }: {
  home-manager.users.jr.programs.kitty = {
    enable = true;
    settings = {
      font_family = "FiraCode Nerd Font";
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
    };
  };
}
