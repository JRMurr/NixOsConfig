{ pkgs, lib, config, ... }:
with lib;
let gcfg = config.myOptions.graphics;
in { config = lib.mkIf gcfg.enable { boot.plymouth = { enable = true; }; }; }
