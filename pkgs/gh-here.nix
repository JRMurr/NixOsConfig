{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage {
  pname = "gh-here";
  version = "4.1.1";

  src = fetchFromGitHub {
    owner = "corywilkerson";
    repo = "gh-here";
    rev = "v4.1.1";
    hash = "sha256-dXomfxMJ7j2IeliHYZvjVvaahNq58qIJ8V5D5DK100I=";
  };

  npmDepsHash = "sha256-o0zK18ZMwr+8Yhbmfpg5fvYdUyZON0ueeGMHFAt96eo=";

  # playwright is a devDependency for UI tests only
  env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

  meta = {
    description = "Local browser for a directory's files and uncommitted diffs";
    homepage = "https://github.com/corywilkerson/gh-here";
    license = lib.licenses.mit;
    mainProgram = "gh-here";
  };
}
