final: prev':

let
  extras = import ./default.nix final;
  prev = prev'; # TODO: not sure why i need this..
in {
  inherit (extras) caddyWithPlugins;

  # TODO: pr to nix-pkgs
  mopidy-iris = prev.mopidy-iris.overrideAttrs (old: rec {
    pname = "Mopidy-Iris";
    version = "3.68.0";
    src = prev.fetchPypi {
      inherit pname version;
      sha256 = "sha256-VcswsdBBJNmy2vdB3ADkS5DxlODFWYD6Hx12zYk+JGQ=";
    };
  });

  lastpass-cli = prev.lastpass-cli.overrideAttrs (old: rec {
    pname = "lastpass-cli";
    version = "1.3.6";
    src = prev.fetchFromGitHub {
      owner = "lastpass";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-ntUBwZ0bVkkpvWK/jQBkLNpCYEDI14/ki0cLwYpEWXk=";
    };
  });
}
