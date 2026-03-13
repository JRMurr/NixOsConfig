{ pkgs, ... }:

{
  imports = [
    ./claude
    # ./codex
  ];

  config = {
    home.packages = with pkgs.llm-agents; [
      # agent-browser
      ccusage
      # agent-deck
      # backlog-md
    ];
  };
}
