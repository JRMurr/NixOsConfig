{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  gcfg = osConfig.myOptions.graphics;
  rofi-themes =
    with pkgs;
    stdenv.mkDerivation rec {
      pname = "rofi-themes-collection";
      version = "ec731cef79d39fc7ae12ef2a70a2a0dd384f9730";
      src = fetchFromGitHub {
        owner = "newmanls";
        repo = pname;
        rev = version;
        hash = "sha256-96wSyOp++1nXomnl8rbX5vMzaqRhTi/N7FUq6y0ukS8=";
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
    let
      mkLiteral = config.lib.formats.rasi.mkLiteral;
    in
    {
      "@import" = getRofiTheme "rounded-blue-dark";
      "#inputbar" = {
        children = map mkLiteral [
          # "prompt"
          "entry"
        ];
      };
      "mainbox" = {
        children = [
          "mode-switcher"
          "inputbar"
          "listview"
        ];
      };
      "button normal.active" = {
        "text-color" = mkLiteral "var(bg3)";
      };
      "button selected.normal" = {
        "text-color" = mkLiteral "var(bg3)";
      };
      "button selected.active" = {
        "text-color" = mkLiteral "var(bg3)";
      };
    };

in
{
  config = lib.mkIf gcfg.enable {

    home.packages = with pkgs; [
      rofi-power-menu
      # rofi-themes
    ];

    catppuccin.rofi = {
      enable = false;
    };

    programs.rofi = {
      package = pkgs.rofi;
      enable = true;
      theme = myTheme;
      terminal = "${pkgs.kitty}/bin/kitty";
      plugins = [ pkgs.rofi-calc ];
      extraConfig = {
        # https://github.com/davatorium/rofi/blob/next/doc/rofi.1.markdown
        modi = "run,window,calc,ssh,power:rofi-power-menu";
        cache-dir = "${config.xdg.cacheHome}/rofi";
        matching = "fuzzy";
        run-shell-command = "{terminal} --hold {cmd}"; # this is kitty only option on terminal, need to hit shift+return for shell commands to run
      };
    };
  };
}
