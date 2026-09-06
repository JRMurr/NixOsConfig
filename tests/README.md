# Tests

NixOS VM tests, exposed as flake `checks`. Run one with:

```bash
nix build .#checks.x86_64-linux.harmonia -L
```

## test-key.sec / test-key.pub

A throwaway binary-cache signing keypair used **only** by `harmonia.nix` inside the VM.
It is committed in the clear on purpose: NixOS VM tests need the key in the store, and
these VMs are torn down at the end of the run.

The real `cache.jrnet.win` key is never in this repo — its private half lives in the
agenix `nix-secrets` repo, its public half in `common/default.nix`.
