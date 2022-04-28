{ pkgs, lib, config, nixosConfig, ... }:
let gcfg = nixosConfig.myOptions.graphics;
in {
  config = lib.mkIf gcfg.enable {
    # try to use stuff from https://github.com/adi1090x/rofi
    programs.rofi = {
      enable = true;
      theme = "Arc-Dark";
      terminal = "${pkgs.kitty}/bin/kitty";
      extraConfig = {
        # https://github.com/davatorium/rofi/blob/next/doc/rofi.1.markdown
        modi = "run,window,ssh";
        cache-dir = "~/.cache/rofi";
        matching = "fuzzy";
        run-shell-command =
          "{terminal} --hold {cmd}"; # this is kitty only option on terminal, need to hit shift+return for shell commands to run
      };
    };
  };
}
