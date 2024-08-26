{}: {

  common = {
    path = ./common;
    description =
      "flake with direnv and flake utils + some commonly usage cli tools";
  };


  zig = {
    path = ./zig;
    description =
      "flake with direnv and flake utils + zig";
  };

  rust = {
    path = ./rust;
    description = "common template + rust";
    welcomeText = ''
      # Simple Rust/Cargo Template

      Please update the rust-toolchain to the latest nightly

      Add this projects name to rust.nix

      run cargo init (for cwd)

      run cargo new (to specify a new dir)

      ## More info
      - Rust Overlay (https://github.com/oxalica/rust-overlay)

    '';
  };

  rust-bevy = {
    path = ./bevy;
    description = "common template + bevy deps";
    welcomeText = ''
      # Bevy Template

      Please update the rust-toolchain to the latest nightly

      Add this projects name to rust.nix and cargo.nix

      ## More info
      - Rust Overlay (https://github.com/oxalica/rust-overlay)

    '';
  };
}
