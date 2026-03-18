{
  pkgs,
  lib,
  osConfig,
  inputs,
  ...
}:
let
  gsd = inputs.get-shit-done;
in
{
  programs.claude-code = {
    enable = true;
    package = pkgs.llm-agents.claude-code;
    skills = { };
    mcpServers = {
      # nixos = {
      #   command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
      # };
      backlog = {
        type = "stdio";
        command = "backlog";
        args = [ "mcp" "start" ];
        env = { };
      };
    };
    memory.source = ../memory.md;
  };

  # home.file.".claude/skills/agent-browser" = {
  #   source = "${pkgs.llm-agents.agent-browser}/etc/agent-browser/skills/agent-browser";
  #   recursive = true;
  # };

  # ===========================================================================
  # Get Shit Done (GSD) - meta-prompting & context engineering system
  # https://github.com/gsd-build/get-shit-done
  # ===========================================================================
  home.file.".claude/commands/gsd" = {
    source = "${gsd}/commands/gsd";
    recursive = true;
  };
  home.file.".claude/get-shit-done" = {
    source = "${gsd}/get-shit-done";
    recursive = true;
  };
  home.file.".claude/agents" = {
    source = "${gsd}/agents";
    recursive = true;
  };
  home.file.".claude/hooks" = {
    source = "${gsd}/hooks";
    recursive = true;
  };

  home.file.".config/ccstatusline/settings.json".text = builtins.toJSON {
    version = 3;
    lines = [
      [
        { id = "1"; type = "model"; color = "cyan"; }
        { id = "2"; type = "separator"; }
        { id = "3"; type = "context-length"; color = "brightBlack"; }
        { id = "4"; type = "separator"; }
        { id = "5"; type = "git-branch"; color = "magenta"; }
        { id = "6"; type = "separator"; }
        { id = "7"; type = "git-changes"; color = "yellow"; }
        { id = "a5faa01e-18da-4ddc-b105-086822e66d9d"; type = "separator"; }
        { id = "b579ea7b-54b0-438c-837f-7875f740c361"; type = "output-style"; }
      ]
      [
        { id = "4a714199-de29-4bfa-9b47-47adbde22603"; type = "tokens-cached"; color = "yellow"; }
        { id = "29af9665-ccae-44a6-80b5-c304b1fb75ec"; type = "separator"; }
        { id = "78890ee1-29a2-4654-919b-a17d9f134510"; type = "tokens-total"; }
        { id = "19271ee5-4b52-4af5-8492-78e3aa3fb8fb"; type = "separator"; }
        { id = "87cbd4ab-efcd-4fd5-9f0c-7d0ab2ab4ee5"; type = "session-cost"; }
        { id = "9b8276a3-b6c6-425d-b9de-bdebf9e7a483"; type = "flex-separator"; }
        { id = "80782c4f-f16c-4eff-82a5-e5ef3b64fd27"; type = "block-timer"; }
        { id = "5b3c093c-1495-4db4-9bcf-09a068b89b98"; type = "separator"; }
        { id = "273ee9f5-7e76-4298-a679-33c13b50bb3a"; type = "session-clock"; }
      ]
      [ ]
      [ ]
    ];
    flexMode = "full-minus-40";
    compactThreshold = 60;
    colorLevel = 3;
    inheritSeparatorColors = false;
    globalBold = false;
    powerline = {
      enabled = false;
      separators = [ "" ];
      separatorInvertBackground = [ false ];
      startCaps = [ ];
      endCaps = [ ];
      autoAlign = false;
    };
  };

  home.packages = with pkgs.llm-agents; [
    ccstatusline
  ];
}
