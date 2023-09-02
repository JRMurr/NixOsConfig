#!/usr/bin/env bash
set -e -u -o pipefail
on_error(){
  popd
}
 
trap 'on_error' ERR

pushd /etc/nixos
# always use the latest of mine
nix flake lock  --update-input secrets

popd
