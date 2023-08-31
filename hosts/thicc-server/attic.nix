{ pkgs, inputs, ... }:
let
  passwords = import inputs.passwords;

  # tokens https://docs.attic.rs/reference/atticadm-cli.html#atticadm-make-token
  getAdminToken = pkgs.writeShellScriptBin "attic-admin-token" ''
    atticd-atticadm make-token --sub "thicc-server" \
     --validity "1day" \
     --push "*" \
     --pull "*" \
     --delete "*" \
     --configure-cache-retention "*" \
     --create-cache "*" \
     --configure-cache "*" \
     --destroy-cache "*"
  '';

  atticAdminLogin = pkgs.writeShellScriptBin "attic-admin-login" ''
    TOKEN=$(${getAdminToken}/bin/attic-admin-token)
    attic login local https://thicc-server.tail19e8e.ts.net/attic/ --set-default $token
  '';

in {
  services.atticd = {
    enable = true;

    # Replace with absolute path to your credentials file
    credentialsFile = "/etc/atticd.env";

    # https://github.com/zhaofengli/attic/blob/main/server/src/config-template.toml
    settings = {
      listen = "[::]:8080";
      api-endpoint = "https://thicc-server.tail19e8e.ts.net/attic/";

      storage = {
        type = "s3";
        bucket = "cache";
        region = "us-east-1";
        endpoint = "http://fatnas:7000";
        credentials = {
          access_key_id = "minio";
          secret_access_key =
            passwords.minio; # copies to nix store but don't care since minio is behind tailscale...
        };
      };

      # Data chunking
      #
      # Warning: If you change any of the values here, it will be
      # difficult to reuse existing chunks for newly-uploaded NARs
      # since the cutpoints will be different. As a result, the
      # deduplication ratio will suffer for a while after the change.
      chunking = {
        # The minimum NAR size to trigger chunking
        #
        # If 0, chunking is disabled entirely for newly-uploaded NARs.
        # If 1, all NARs are chunked.
        nar-size-threshold = 64 * 1024; # 64 KiB

        # The preferred minimum size of a chunk, in bytes
        min-size = 16 * 1024; # 16 KiB

        # The preferred average size of a chunk, in bytes
        avg-size = 64 * 1024; # 64 KiB

        # The preferred maximum size of a chunk, in bytes
        max-size = 256 * 1024; # 256 KiB
      };
    };
  };

  # stolen from https://github.com/heywoodlh/nixos-configs/blob/master/nixos/roles/nixos/cache.nix
  # and https://github.com/xddxdd/nixos-config/blob/master/nixos/optional-cron-jobs/rebuild-nixos-config.nix 
  systemd.timers."nix-cache-build" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Unit = "nix-cache-build.service";
    };
  };
  # TODO: figure out auto login need to have the attic module somehow expose atticadmWrapper

  # sudo systemctl start nix-cache-build.service
  systemd.services."nix-cache-build" = {
    path = with pkgs; [ git nixos-rebuild attic-client ];
    environment = {
      HOME = "/run/nix-cache-build";
      XDG_CONFIG_HOME = "/run/nix-cache-build/config";
    };
    script = ''
      set -eu
      rm -rf /tmp/nixos-configs
      # if weird error make sure has no new lines (echo -n)
      attic login --set-default local https://thicc-server.tail19e8e.ts.net/attic/ "$(cat ${passwords.atticTokenPath})"
      RUST_BACKTRACE=1  attic cache info main

      git clone https://github.com/JRMurr/NixOsConfig /tmp/nixos-configs

      nixos-rebuild build --flake /tmp/nixos-configs#thicc-server
      attic push main ./result/

      rm -rf /tmp/nixos-configs
    '';
    serviceConfig = {
      Type = "oneshot";
      RuntimeDirectory = "nix-cache-build";
      WorkingDirectory = "/run/nix-cache-build";
      RuntimeDirectoryPreserve = true;
      # User = "root";
    };
  };

  environment.systemPackages = [ atticAdminLogin ];
}
