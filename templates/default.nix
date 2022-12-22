{ }: {

  common = {
    path = ./common;
    description =
      "flake with direnv and flake utils + some commonly usage cli tools";
  };

  rust = {
    path = ./rust;
    description = "common template + rust";
    welcomeText = ''
      # Simple Rust/Cargo Template

      Please update the rust-toolchain to the latest nightly

      Add this projects name to rust.nix

      ## More info
      - [Rust Overlay](https://github.com/oxalica/rust-overlay)

    '';
  };
}
