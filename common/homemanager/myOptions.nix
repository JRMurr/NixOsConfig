{ lib, ... }:
{
  # Home-manager mirror of the system options in common/myOptions. On NixOS
  # hosts ./fromOs.nix copies the system values over; standalone configurations
  # (hosts/frame) set them directly.
  options.myOptions = with lib; {
    graphics.enable = mkEnableOption "Enable graphics";

    llm.skills = mkOption {
      # Keep in sync with common/myOptions/llm.nix, which owns the enum.
      type = types.listOf types.str;
      default = [ ];
      description = "Agent skills to install for coding agents.";
    };
  };
}
