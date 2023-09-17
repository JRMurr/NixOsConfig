{ pkgs, gitignore }:

let
  rustVersion = (pkgs.rust-bin.fromRustupToolchainFile
    ./rust-toolchain.toml); # rust-bin.stable.latest.default
  rustPlatform = pkgs.makeRustPlatform {
    cargo = rustVersion;
    rustc = rustVersion;
  };
  linuxDeps = pkgs.lib.optionals pkgs.stdenv.isLinux (with pkgs; [
    udev
    alsa-lib
    vulkan-loader
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr # To use the x11 feature
    libxkbcommon
    wayland # To use the wayland feature
  ]);

  macDeps = pkgs.lib.optionals pkgs.stdenv.isDarwin [
    pkgs.darwin.apple_sdk.frameworks.Cocoa
    rustPlatform.bindgenHook
  ];

  nativeDeps = linuxDeps ++ macDeps;

  name = "TODO:FILL ME";
  version = "0.1.0";
  rustBin = rustPlatform.buildRustPackage {
    pname = name;
    version = version;
    src = gitignore.lib.gitignoreSource ./.;
    cargoLock.lockFile = ./Cargo.lock;
    nativeBuildInputs = nativeDeps;
  };
in {
  rust-shell =
    (rustVersion.override { extensions = [ "rust-src" "rust-analyzer" ]; });
  binary = rustBin;
  rustPlatform = rustPlatform;
  nativeDeps = nativeDeps;
}
