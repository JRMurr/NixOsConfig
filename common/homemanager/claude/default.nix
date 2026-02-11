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
    skills = {
      agent-browser = "${pkgs.llm-agents.agent-browser}/etc/agent-browser/skills/agent-browser";
    };
    mcpServers = {
      nixos = {
        command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
      };
    };
  };

  home.packages = with pkgs; [
    llm-agents.agent-browser
    llm-agents.ccusage
  ];
}
