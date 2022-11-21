{ pkgs, config, lib, nixosConfig, ... }:
let gcfg = nixosConfig.myOptions.graphics;
in {
  config = lib.mkIf (pkgs.stdenv.isDarwin || gcfg.enable) {
    programs.kitty = {
      enable = true;
      settings = {
        font_family = "FiraCode Nerd Font";
        bold_font = "auto";
        italic_font = "auto";
        bold_italic_font = "auto";
        enable_audio_bell = false;
        scrollback_lines = -1;
        tab_bar_edge = "top";
        allow_remote_control = "yes";
        shell_integration = "enabled";
        macos_option_as_alt = "yes";
      };
      theme = "Dracula";
    };
  };
}
