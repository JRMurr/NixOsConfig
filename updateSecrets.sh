#!/usr/bin/env bash
set -e -u -o pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
on_error(){
  popd
}

trap 'on_error' ERR

pushd $SCRIPT_DIR
# always use the latest of mine
nix flake lock  --update-input secrets

popd
