{ pkgs, ... }: {
  programs.nushell = {
    enable = true;
    configFile = { source = ./config.nu; };
    shellAliases = {
      ll = "ls -l";
    };
  };
}
