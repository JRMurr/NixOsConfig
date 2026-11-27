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
      # agent-deck
      # backlog-md
    ]
    # the agent-browser skill drives this CLI
    ++ lib.optional (builtins.elem "agent-browser" config.myOptions.llm.skills)
      pkgs.llm-agents.agent-browser
    # the rex skill and hook call this CLI
    ++ lib.optional (builtins.elem "rex" config.myOptions.llm.skills) pkgs.rex;
  };
}
