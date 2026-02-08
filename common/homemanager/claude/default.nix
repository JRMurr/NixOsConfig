{
  pkgs,
  lib,
  osConfig,
  ...
}:
{
  home.packages = with pkgs; [
    claude-code
    ccusage
  ];
}
