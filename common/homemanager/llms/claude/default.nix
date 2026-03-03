{
  pkgs,
  lib,
  osConfig,
  ...
}:
{
  programs.claude-code = {
    enable = true;
    package = pkgs.llm-agents.claude-code;
    skills = { };
    # mcpServers = {
    #   nixos = {m
    #     command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
    #   };
    # };
    memory.source = ../memory.md;
  };

  home.file.".claude/skills/agent-browser" = {
    source = "${pkgs.llm-agents.agent-browser}/etc/agent-browser/skills/agent-browser";
    recursive = true;
  };

  home.packages = with pkgs.llm-agents; [
    ccstatusline # TODO: set the config of this
  ];
}
