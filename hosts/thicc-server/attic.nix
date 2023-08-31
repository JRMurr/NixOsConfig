{ pkgs, inputs, ... }:
let passwords = import inputs.passwords;
in {
  # tokens https://docs.attic.rs/reference/atticadm-cli.html#atticadm-make-token
  # make admin token for 1 month 
  # sudo atticd-atticadm make-token --sub "thicc-server" --validity "1month" --push "*" --pull "*" --delete "*" --configure-cache-retention "*" --create-cache "*" --configure-cache "*" --destroy-cache "*"
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
        region = "does-not-matter";
        endpoint = "fatnas:7001";
        credentials = {
          access_key_id = "minio";
          secret_access_key = passwords.minio;
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
}
