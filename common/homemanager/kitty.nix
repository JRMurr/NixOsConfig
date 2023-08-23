{ pkgs, config, lib, nixosConfig, ... }:
let gcfg = nixosConfig.myOptions.graphics;
in {
  config = lib.mkIf (pkgs.stdenv.isDarwin || gcfg.enable) {
    programs.kitty = {
      enable = true;
      shellIntegration.enableFishIntegration = true;
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
        shell = "fish";
      };
      theme = "Dracula";
    };

    # xdg.configFile."kitty/diff.conf" = {
    #   text = ''
    #     pygments_style dracula

    #     # dracula
    #     foreground           #f8f8f2
    #     background           #282a36
    #     title_fg             #f8f8f2
    #     title_bg             #282a36
    #     margin_bg            #6272a4
    #     margin_fg            #44475a
    #     removed_bg           #ff5555
    #     highlight_removed_bg #ff5555
    #     removed_margin_bg    #ff5555
    #     added_bg             #50fa7b
    #     highlight_added_bg   #50fa7b
    #     added_margin_bg      #50fa7b
    #     filler_bg            #44475a
    #     hunk_margin_bg       #44475a
    #     hunk_bg              #bd93f9
    #     search_bg            #8be9fd
    #     search_fg            #282a36
    #     select_bg            #f1fa8c
    #     select_fg            #282a36
    #   '';
    # };
  };

}
