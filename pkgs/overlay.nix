final: prev:

let extras = import ./default.nix final;

in { inherit (extras) caddyWithPlugins; }
