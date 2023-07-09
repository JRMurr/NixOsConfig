{ config, lib, ... }: {
  options = with lib; {
    myOptions.tailscale = {
      tailNetName = mkOption {
        type = types.str;
        default = "tail19e8e.ts.net";
        description = "tailnet name";
      };
    };
  };
}
