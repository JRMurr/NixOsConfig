{ pkgs, lib, config, ... }:
let xdgConfig = config.home-manager.users.jr.xdg;
in {

  # try to use stuff from https://github.com/adi1090x/rofi
  home-manager.users.jr = {
    programs.rofi = {
      enable = true;
      theme = "Arc-Dark";
      terminal = "${pkgs.kitty}/bin/kitty";
      extraConfig = {
        # https://github.com/davatorium/rofi/blob/next/doc/rofi.1.markdown
        modi = "run,window,ssh";
        cache-dir = "${xdgConfig.cacheHome}/rofi";
        matching = "fuzzy";
        run-shell-command =
          "{terminal} --hold {cmd}"; # this is kitty only option on terminal, need to hit shift+return for shell commands to run
      };
    };
  };
}
