# Deferred items

Incidental things noticed while working, not blocking anything.

## `nix-cache-build` cannot build `framework` or `desktop`

Both fail on `vscode-extension-catppuccin-vscode`, whose pnpm-deps FOD fetches from
`registry.npmjs.org`. It gets ~444 of 581 packages then dies on `ETIMEDOUT`.

Measured from thicc-server: tarball fetches to `registry.npmjs.org` succeed 3 times in 5,
taking 1.3-5.4s, and hang past 15s the rest of the time. The npmjs *metadata* endpoint,
`cache.nixos.org` and `github.com` are all fast and reliable, so this is specific to the
npmjs tarball CDN, not general connectivity.

Unrelated to the binary cache work - the same derivation fails when built by hand. Worth
noting the old attic job wrapped each host in `|| true`, so this would have failed silently
and the cache would simply never have contained these two hosts.

Options if it keeps happening: retry each host build in the job, or pre-seed the FOD.

## `wsl` host does not evaluate

`nix eval .#nixosConfigurations.wsl.config.system.build.toplevel.drvPath` fails:

```
Failed assertions:
- age.identityPaths must be set, for example by enabling openssh.
```

Pre-existing (fails on `main` too). It is the only host not covered by the
`nix-cache-build` job, because it cannot be built at all.

## `myOptions.tailscale.tailNetName` is declared but never read

`common/myOptions/tailscale.nix` defines `tailNetName = "tail19e8e.ts.net"`, but nothing
consumes it. Meanwhile `common/tailscale.nix` hardcodes a different, older-style domain in
`networking.search`: `johnreillymurray.gmail.com.beta.tailscale.net`. One of the two is stale.

## thicc-server's tailscale IP is hardcoded in two places

`100.95.204.122` appears in `hosts/thicc-server/postgres.nix:9` (already carries a
`TODO: make this a config option`) and `hosts/thicc-server/blocky/default.nix:74-79`.
Blocky's `jrnet.win` mapping is what makes `cache.jrnet.win` resolve internally, so this
one matters to the binary cache.

## Dead cachix leftovers

`scripts/pushStore.sh` still pushes to `jrmurr` cachix, which was commented out of
`common/default.nix` in `d607f6c`. `cachix` is still in
`common/homemanager/programs.nix:66`. Harmless, just unused.

## tailscale is logged out on thicc-server

`tailscale status` reports `Logged out.` while `tailscaled` is active. Nothing that depends
on the tailnet (including internal `cache.jrnet.win` resolution via blocky) works until
`tailscale up` is run.
