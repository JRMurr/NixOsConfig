{ config, lib, ... }:
{
  options = with lib; {
    myOptions.tailscale = {
      enable = mkOption {
        default = true;
        example = true;
        description = "enable tailscale";
        type = lib.types.bool;
      };
      tailNetName = mkOption {
        type = types.str;
        default = "tail19e8e.ts.net";
        description = "tailnet name";
      };
    };
  };
}
