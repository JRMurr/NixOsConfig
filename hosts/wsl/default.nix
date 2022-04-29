{ config, pkgs, ... }: {
  imports = [
    ../../common
    # ./nix-ld-vscode.nix
  ];
  networking.hostName = "wsl";
  myOptions.graphics.enable = false;
  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = "jr";
    startMenuLaunchers = true;
  };
}
