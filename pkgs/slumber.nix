{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "slumber";
  version = "4.2.0";

  src = fetchFromGitHub {
    owner = "LucasPickering";
    repo = "slumber";
    rev = "v${version}";
    hash = "sha256-wEQPyp0J7p2TuJwH/fQv5fhenUY3MNIq0oazFJAj9lM=";
  };

  cargoHash = "sha256-Nz/Z2KJ8jJAsTASwnvleRpJ88UHGe7dktO0FkCOPdu4=";

  meta = {
    description = "Terminal-based HTTP/REST client";
    homepage = "https://github.com/LucasPickering/slumber";
    changelog = "https://github.com/LucasPickering/slumber/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "slumber";
  };
}
