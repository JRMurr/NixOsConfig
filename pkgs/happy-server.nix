# Adapted from https://github.com/numtide/llm-agents.nix/pull/1279
# Updated to use the monorepo (slopus/happy) since the standalone repo
# (slopus/happy-server) has been merged there.
{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchYarnDeps,
  yarnConfigHook,
  yarnInstallHook,
  nodejs,
  makeWrapper,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "happy-server";
  version = "0-unstable-2025-11-28";

  src = fetchFromGitHub {
    owner = "slopus";
    repo = "happy-server";
    rev = "84ed0273024469b204e59d97002069765f20086d";
    hash = "sha256-fH9SeYGwvnOKeD6F9nk316YnP83dX+CtYUtqlCYj5LM=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    hash = "sha256-zTdeLQowJWLJE5SHubnHUnRGHvmdhCNq+6jJ77UdCCo=";
  };

  nativeBuildInputs = [
    nodejs
    yarnConfigHook
    yarnInstallHook
    makeWrapper
  ];

  # Runs tsx (TypeScript execute) directly against the source —
  # no separate build/compile step needed.
  postInstall = ''
    mkdir -p $out/bin
    packageDir="$out/lib/node_modules/happy-server"
    makeWrapper ${lib.getExe nodejs} $out/bin/happy-server \
      --add-flags "--import $packageDir/node_modules/tsx/dist/esm/index.mjs" \
      --add-flags "$packageDir/sources/main.ts" \
      --chdir "$packageDir" \
      --set NODE_PATH "$packageDir/node_modules"
  '';

  meta = {
    description = "Minimal backend for open-source end-to-end encrypted Claude Code clients";
    homepage = "https://github.com/slopus/happy-server";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    mainProgram = "happy-server";
  };
})
