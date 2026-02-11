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
    mcpServers = {
      nixos = {
        command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
      };
    };
  };

  home.packages = with pkgs; [
    llm-agents.ccusage
  ];
}
