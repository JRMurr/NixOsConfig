{
  pkgs,
  lib,
  osConfig,
  ...
}:
{
  programs.codex = {
    enable = true;
    package = pkgs.llm-agents.codex;
    # mcpServers = {
    #   nixos = {m
    #     command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
    #   };
    # };
    custom-instructions = builtins.readFile ../memory.md;
  };

  # home.file.".claude/skills/agent-browser" = {
  #   source = "${pkgs.llm-agents.agent-browser}/etc/agent-browser/skills/agent-browser";
  #   recursive = true;
  # };
}
