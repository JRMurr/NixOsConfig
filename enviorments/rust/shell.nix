{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [ gcc cmake openssl zlib pkgconfig postgresql_12 ];
}
