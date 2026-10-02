# Drives `jr etc` against a scratch root (JR_ROOT), which also skips the sudo
# re-exec and the systemd side effects.
{ pkgs }:
let
  mkJr = import ./. { inherit pkgs; };

  before = mkJr {
    switchCmd = "true";
    buildCmd = "true";
    etc = {
      "tmpfiles.d/gpu.conf" = "L+ /run/opengl-driver - - - - /nix/store/old\n";
      "systemd/system/user@.service.d/nix.conf" = "[Unit]\nAfter=nix.mount\n";
    };
  };

  after = mkJr {
    switchCmd = "true";
    buildCmd = "true";
    etc."tmpfiles.d/gpu.conf" = "L+ /run/opengl-driver - - - - /nix/store/new\n";
  };
in
pkgs.runCommand "jr-etc-test" { } ''
  set -euo pipefail
  export JR_ROOT=$PWD/root
  fail() { echo "FAIL: $*" >&2; exit 1; }

  mkdir -p root/etc/tmpfiles.d
  echo keep > root/etc/unmanaged.conf
  # What non-nixos-gpu-setup leaves behind: a link into the store.
  echo stale > store-target
  ln -s $PWD/store-target root/etc/tmpfiles.d/gpu.conf

  ${before}/bin/jr etc --check && fail "check passed before install"

  ${before}/bin/jr etc
  [[ -L root/etc/tmpfiles.d/gpu.conf ]] && fail "symlink not replaced"
  grep -q /nix/store/old root/etc/tmpfiles.d/gpu.conf || fail "gpu.conf content"
  [[ $(cat store-target) == stale ]] || fail "wrote through the old symlink"
  grep -q nix.mount 'root/etc/systemd/system/user@.service.d/nix.conf' || fail "drop-in missing"
  ${before}/bin/jr etc --check || fail "check failed right after install"

  echo edited > root/etc/tmpfiles.d/gpu.conf
  ${before}/bin/jr etc --check && fail "check missed a local edit"
  ${before}/bin/jr etc
  ${before}/bin/jr etc --check || fail "edit not repaired"

  ${after}/bin/jr etc --check && fail "check missed a stale file"
  ${after}/bin/jr etc
  grep -q /nix/store/new root/etc/tmpfiles.d/gpu.conf || fail "gpu.conf not updated"
  [[ -e 'root/etc/systemd/system/user@.service.d/nix.conf' ]] && fail "stale drop-in kept"
  [[ $(cat root/etc/unmanaged.conf) == keep ]] || fail "unmanaged file touched"
  ${after}/bin/jr etc --check || fail "not idempotent"

  touch $out
''
