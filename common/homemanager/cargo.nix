{ pkgs, ... }:
let
  tomlFormat = pkgs.formats.toml { };
  # https://doc.rust-lang.org/cargo/reference/config.html
  opts = {
    net.git-fetch-with-cli = true;
  };

in
{
  home.file.cargoToml = {
    source = tomlFormat.generate "cargo.toml" opts;
    target = ".cargo/config.toml";
  };
}
