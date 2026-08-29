{
  pkgs,
  lib,
  osConfig,
  ...
}:

{
  imports = [
    ./claude
    # ./codex
  ];

  config = {
    home.packages = with pkgs.llm-agents; [
      ccusage
      # agent-deck
      # backlog-md
    ]
    # the agent-browser skill drives this CLI
    ++ lib.optional (builtins.elem "agent-browser" osConfig.myOptions.llm.skills)
      pkgs.llm-agents.agent-browser;
  };
}
