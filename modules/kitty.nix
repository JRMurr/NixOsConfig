{ pkgs, config, lib, ... }: {
  home-manager.users.jr.programs.kitty = {
    enable = true;
    settings = {
      font_family = "FiraCode Nerd Font";
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      enable_audio_bell = false;
      scrollback_lines = -1;
    };
    # theme
    extraConfig = lib.fileContents /etc/nixos/dotFiles/kitty/kitty-themes/Dracula.conf;
  };
}
