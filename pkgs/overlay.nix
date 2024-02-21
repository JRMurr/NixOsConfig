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

  mopidy-spotify = prev.mopidy-spotify.overridePythonAttrs (old: rec {
    pname = "mopidy-spotify";
    version = "unstable-2023-11-1";
    src = prev.fetchFromGitHub {
      owner = "mopidy";
      repo = "mopidy-spotify";
      rev = "48faaaa2642647b0152231798b46ccd9631694f5";
      hash = "sha256-RwkUdcbDU7/ndVnPteG/iXB2dloljvCHQlvPk4tacuA=";
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

  # build from develop since no release has been made in a while but dev branch has fix for building on gcc 13
  # snapcast = prev.snapcast.overrideAttrs (old: rec {
  #   src = prev.fetchFromGitHub {
  #     owner = "badaix";
  #     repo = "snapcast";
  #     rev = "2355dca98dba711e4102cb1502bcef04878103e8";
  #     hash = "sha256-FVAQ/BPJDEZhbuKOap8Ezq+twVpJh7hupR+0c5KLIEw=";
  #   };
  # });
}
