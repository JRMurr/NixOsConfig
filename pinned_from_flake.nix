{ }:
let
  inherit (builtins) fetchTree fromJSON readFile;
  inherit ((fromJSON (readFile ./flake.lock)).nodes) nixpkgs_7; # TODO: how do i make sure im picking mine?

  pkgs = import (fetchTree nixpkgs_7.locked) { overlays = [ ]; };
in
{
  inherit pkgs;
}
