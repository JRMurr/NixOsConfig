{ config, pkgs, ... }: {
  # setup vscode with the flake from https://github.com/sonowz/vscode-remote-wsl-nixos
  imports = [ ../../common ];
  networking.hostName = "wsl";
  myOptions.graphics.enable = false;
  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = "jr";
    startMenuLaunchers = true;
  };
}
