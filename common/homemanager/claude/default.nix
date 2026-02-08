{
  pkgs,
  lib,
  osConfig,
  ...
}:
{
  home.packages = with pkgs; [
    llm-agents.claude-code
    llm-agents.ccusage
  ];
}
