{ pkgs, config, ... }:
let
  cfg = config.myOptions.jr;
in
{
  home.packages = [
    (import ../../pkgs/jr { inherit pkgs; } {
      inherit (cfg) switchCmd buildCmd postSwitchCmd;
    })
  ];
}
