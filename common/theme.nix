{ config, lib, ... }:
let

  gcfg = config.myOptions.graphics;
in
{
  config = lib.mkIf gcfg.enable
    {
      catppuccin.enable = true;
    };
}
