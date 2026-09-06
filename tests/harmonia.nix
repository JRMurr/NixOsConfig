# Proves the binary cache actually works end to end:
#   1. a client with only our cache as a substituter can fetch a path it cannot build
#   2. it refuses that same path when our public key is not trusted
#
# (2) is the important half. Without it the test would still pass if signing were
# silently disabled, which is exactly the failure mode we care about.
{ pkgs, lib, ... }:
let
  testPubKey = lib.fileContents ./test-key.pub;

  # Well formed but wrong, so the negative case proves keys are compared
  # rather than merely proving the trusted list was non-empty.
  decoyPubKey = lib.fileContents ./decoy-key.pub;

  # Unique to this test, so the client cannot already have it in its own closure.
  probe = pkgs.runCommand "harmonia-probe" { } "echo tailnet-cache-probe > $out";

  # Forbids local building, so a "success" can only mean the path was substituted.
  substituteOnly = "--max-jobs 0";
in
{
  name = "harmonia-cache";

  nodes = {
    server = {
      services.harmonia.cache = {
        enable = true;
        signKeyPaths = [ ./test-key.sec ];
        settings = {
          bind = "[::]:5000";
          priority = 30;
        };
      };

      networking.firewall.allowedTCPPorts = [ 5000 ];

      # Put the probe in the server's store without the client seeing it.
      system.extraDependencies = [ probe ];
    };

    client = {
      nix.settings = {
        substituters = lib.mkForce [ "http://server:5000" ];
        trusted-public-keys = lib.mkForce [ testPubKey ];
        require-sigs = true;
      };
    };
  };

  testScript = ''
    start_all()

    # harmonia is socket activated: the service stays inactive until first
    # connection, so wait on the socket rather than the service.
    server.wait_for_unit("harmonia.socket")
    server.wait_for_open_port(5000)

    client.wait_until_succeeds("curl -f http://server:5000/nix-cache-info >&2")
    client.succeed("curl -f http://server:5000/nix-cache-info | grep -q 'Priority: 30'")

    # The client must not already have the probe, or the test proves nothing.
    client.fail("nix-store --check-validity ${probe}")

    with subtest("substitutes a signed path it cannot build"):
        client.succeed(
            "nix-store --realise ${probe} --store /root/signed ${substituteOnly}"
        )
        client.succeed("grep -q tailnet-cache-probe /root/signed/${probe}")

    with subtest("refuses the same path when the key is not trusted"):
        client.fail(
            "nix-store --realise ${probe} --store /root/untrusted ${substituteOnly}"
            " --option trusted-public-keys ${decoyPubKey}"
        )
  '';
}
