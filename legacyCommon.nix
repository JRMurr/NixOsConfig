# expose the common module as a non flake

let
  flakeOut = import ./default.nix;
in
flakeOut.nixosModules.default
