{ lib, ... }:
{
  # Home-manager mirror of the system options in common/myOptions. On NixOS
  # hosts ./fromOs.nix copies the system values over; standalone configurations
  # (hosts/frame) set them directly.
  options.myOptions = with lib; {
    graphics.enable = mkEnableOption "Enable graphics";

    rebuildCmd = mkOption {
      type = types.str;
      default = "nh os switch";
      description = ''
        What the `nixRe` alias runs. NixOS hosts rebuild the system; a standalone
        home-manager host switches its own generation instead.
      '';
    };

    nixTooling = mkOption {
      type = types.enum [
        "flakeInputs"
        "nixpkgs"
      ];
      default = "flakeInputs";
      description = ''
        Where nixd, nil and nurl come from. The flake inputs track upstream
        nightlies but are cached for nothing, so on aarch64 they are built from
        source -- nixd links LLVM and takes hours under qemu. nixpkgs' versions
        are a few days behind and come straight from cache.nixos.org.
      '';
    };

    llm.skills = mkOption {
      # Keep in sync with common/myOptions/llm.nix, which owns the enum.
      type = types.listOf types.str;
      default = [ ];
      description = "Agent skills to install for coding agents.";
    };
  };
}
