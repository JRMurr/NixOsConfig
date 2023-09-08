# taken from https://github.com/nevivurn/nixos-config/blob/28cb59209597b8872d611706a412d61567e41ae2/pkgs/caddy-with-plugins/default.nix
{ lib, buildGoModule, caddy, plugins ? [ ]
, vendorHash ? "sha256-K9HPZnr+hMcK5aEd1H4gEg6PXAaNrNWFvaHYm5m62JY=", ... }:

let
  patchScript = lib.concatMapStrings (p: ''
    sed -i '/plug in Caddy modules here/a \\t_ "${p.name}"' cmd/caddy/main.go
  '') plugins;
  getScript = lib.concatMapStrings (p: ''
    go get ${p.name}@${p.version or "latest"}
  '') plugins;

in caddy.override (_: {
  buildGoModule = args:
    buildGoModule (args // {
      postPatch = patchScript;
      postConfigure = ''
        cp vendor/go.mod vendor/go.sum ./
      '';

      overrideModAttrs = (_: {
        postConfigure = getScript;
        postInstall = ''
          cp go.mod go.sum $out/
        '';
      });

      inherit vendorHash;
    });
})
