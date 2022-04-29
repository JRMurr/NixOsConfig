{ lib, pkgs, config, ... }:
with lib;
# https://discourse.nixos.org/t/vscode-remote-wsl-extension-works-on-nixos-without-patching-thanks-to-nix-ld/14615
let
  ldEnv = {
    NIX_LD_LIBRARY_PATH = with pkgs; makeLibraryPath [
      stdenv.cc.cc
    ];
    NIX_LD = removeSuffix "\n" (fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker");
  };
  ldExports = mapAttrsToList (name: value: "export ${name}=${value}") ldEnv;
  joinedLdExports = concatStringsSep "\n" ldExports;
in
{
    environment.systemPackages = with pkgs; [ wget ];
    environment.variables = ldEnv;
    home-manager.users.jr.home.file.".vscode-server/server-env-setup".text = ''
      echo "== '~/.vscode-server/server-env-setup' SCRIPT START =="
      ${joinedLdExports}
      echo "== '~/.vscode-server/server-env-setup' SCRIPT END =="
    '';
}
