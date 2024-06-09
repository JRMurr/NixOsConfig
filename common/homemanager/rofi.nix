{ pkgs, lib, config, nixosConfig, ... }:
let
  gcfg = nixosConfig.myOptions.graphics;
  rofi-themes = with pkgs;
    stdenv.mkDerivation rec {
      pname = "rofi-themes-collection";
      version = "a1bfac5627cc01183fc5e0ff266f1528bd76a8d2";
      src = fetchFromGitHub {
        owner = "newmanls";
        repo = pname;
        rev = version;
        hash = "sha256-0/0jsoxEU93GdUPbvAbu2Alv47Uwom3zDzjHcm2aPxY=";
      };
      buildPhase = "";
      installPhase = ''
        mkdir $out
        cp -r . $out/share
      '';
    };
  # https://github.com/newmanls/rofi-themes-collection/tree/master/themes
  getRofiTheme = theme: "${rofi-themes}/share/themes/${theme}.rasi";

  myTheme =
    let mkLiteral = config.lib.formats.rasi.mkLiteral;
    in {
      # "@import" = getRofiTheme "rounded-blue-dark";
      "#inputbar" = { children = map mkLiteral [ "prompt" "entry" ]; };
      "mainbox" = { children = [ "mode-switcher" "inputbar" "listview" ]; };
      "button normal.active" = { "text-color" = mkLiteral "var(bg3)"; };
      "button selected.normal" = { "text-color" = mkLiteral "var(bg3)"; };
      "button selected.active" = { "text-color" = mkLiteral "var(bg3)"; };
    };

in
{
  config = lib.mkIf gcfg.enable {

    home.packages = with pkgs; [ rofi-power-menu rofi-themes ];

    programs.rofi = {
      enable = true;
      theme = myTheme;
      terminal = "${pkgs.kitty}/bin/kitty";
      plugins = [ pkgs.rofi-calc ];
      extraConfig = {
        # https://github.com/davatorium/rofi/blob/next/doc/rofi.1.markdown
        modi = "run,window,calc,ssh,power:rofi-power-menu";
        cache-dir = "${config.xdg.cacheHome}/rofi";
        matching = "fuzzy";
        run-shell-command =
          "{terminal} --hold {cmd}"; # this is kitty only option on terminal, need to hit shift+return for shell commands to run
      };
    };
  };
}
