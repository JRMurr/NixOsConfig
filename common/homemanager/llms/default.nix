{
  pkgs,
  lib,
  config,
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
    ++ lib.optional (builtins.elem "agent-browser" config.myOptions.llm.skills)
      pkgs.llm-agents.agent-browser;
  };
}
