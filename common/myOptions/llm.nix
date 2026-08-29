{ lib, ... }:
let
  # Skills that can be linked into ~/.claude/skills. Keep in sync with
  # common/homemanager/llms/claude/default.nix.
  allSkills = [
    "agent-browser"
    "hegel"
  ];
in
{
  options = with lib; {
    myOptions.llm = {
      skills = mkOption {
        type = types.listOf (types.enum allSkills);
        default = allSkills;
        example = [ "hegel" ];
        description = "Agent skills to install for coding agents.";
      };
    };
  };
}
