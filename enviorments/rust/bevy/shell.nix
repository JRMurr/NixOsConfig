{ pkgs ? import <nixpkgs> {
  overlays = [
    (import (builtins.fetchTarball
      "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))
  ];
} }:
with pkgs;

mkShell {

  shellHook = ''
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${
      lib.makeLibraryPath [
        # alsaLib
        # udev
        vulkan-loader
        xlibs.libXcursor
        xlibs.libXi
        xlibs.libXrandr
        xorg.libX11
      ]
    }"'';

  buildInputs = [
    (rust-bin.fromRustupToolchainFile ./rust-toolchain)
    # https://blog.thomasheartman.com/posts/bevy-getting-started-on-nixos
    lld
    clang

    # # bevy-specific deps (from https://github.com/bevyengine/bevy/blob/main/docs/linux_dependencies.md)
    pkg-config
    udev
    alsaLib
    # lutris
    x11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    vulkan-tools
    vulkan-headers
    vulkan-loader
    vulkan-validation-layers
  ];
}
