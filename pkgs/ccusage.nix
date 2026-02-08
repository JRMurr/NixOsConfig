{
  fetchPnpmDeps,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ccusage";
  version = "18.0.5";

  src = fetchFromGitHub {
    owner = "ryoppippi";
    repo = "ccusage";
    tag = "v${finalAttrs.version}";
    hash = "sha256-GopiyaY8lfrgV2tRDSy+qC5AndxIHtGbsAJ51mRi8mU=";
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_10
    makeWrapper
  ];

  pnpmWorkspaces = [ "ccusage" "@ccusage/internal" "@ccusage/terminal" ];
  pnpmInstallFlags = [ "--shamefully-hoist" ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs)
      pname
      version
      src
      pnpmWorkspaces
      pnpmInstallFlags
      ;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-PsTe3h1a3q5cxjLMd0t4iYig9VVwYdEc6DgqHRX0nx8=";
  };

  buildPhase = ''
    runHook preBuild

    # Remove pnpm's node shims that point to a non-existent managed node binary
    # (caused by devEngines.runtime in package.json, see pnpm#10282)
    find . -path '*/node_modules/.bin/node' -delete

    # Build workspace dependencies (e.g. @ccusage/internal, @ccusage/terminal)
    pnpm --filter=ccusage^... build

    # Build ccusage itself, skipping generate:schema (needs bun; schema is already in source)
    pnpm --filter=ccusage exec tsdown

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/ccusage $out/bin

    # Copy the source tree preserving pnpm's relative symlink structure
    cp -r node_modules apps packages $out/lib/ccusage/

    # Remove all broken symlinks in the output
    find $out/lib/ccusage -xtype l -delete

    makeWrapper ${nodejs}/bin/node $out/bin/ccusage \
      --add-flags "$out/lib/ccusage/apps/ccusage/dist/index.js"

    runHook postInstall
  '';
})
