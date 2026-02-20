{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  port = 3005;
in
{
  # =========================================================================
  # Redis - Used by happy-server for WebSocket state and caching.
  # =========================================================================
  services.redis.servers.happy = {
    enable = true;
    port = 6379;
    bind = "127.0.0.1";
  };

  # =========================================================================
  # PostgreSQL database for happy-server (Prisma ORM)
  # =========================================================================
  services.postgresql = {
    ensureDatabases = [ "happy" ];
    ensureUsers = [
      {
        name = "happy";
        ensureDBOwnership = true;
      }
    ];
  };

  # =========================================================================
  # Secret containing the SEED value used for token generation.
  # Generate with: openssl rand -hex 32
  # Then add to your agenix secrets as "happy-server-env.age"
  # The file should contain at minimum: SEED=<your-hex-secret>
  # =========================================================================
  age.secrets.happy-server-env = {
    file = "${inputs.secrets}/secrets/happy-server-env.age";
  };

  # =========================================================================
  # happy-server systemd service
  # Runs the Nix-built package directly — no Docker needed.
  # Prisma needs to run migrations on first start; the service runs
  # migrate deploy as a pre-start step.
  # =========================================================================
  systemd.services.happy-server = {
    description = "Happy Server - encrypted relay for Claude Code clients";
    wantedBy = [ "multi-user.target" ];
    after = [
      "postgresql.service"
      "redis-happy.service"
      "network.target"
    ];
    requires = [
      "postgresql.service"
      "redis-happy.service"
    ];

    environment = {
      NODE_ENV = "production";
      PORT = builtins.toString port;
      DATABASE_URL = "postgresql://happy:@localhost:5432/happy";
      REDIS_URL = "redis://localhost:6379";
    };

    path = [ pkgs.nodejs ];

    serviceConfig = {
      EnvironmentFile = config.age.secrets.happy-server-env.path;
      ExecStartPre = "${pkgs.happy-server}/lib/node_modules/happy-server/node_modules/.bin/prisma migrate deploy";
      ExecStart = "${lib.getExe pkgs.happy-server}";
      Restart = "on-failure";
      RestartSec = 5;

      # Hardening
      DynamicUser = true;
      StateDirectory = "happy-server";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
    };
  };

  # =========================================================================
  # Caddy reverse proxy: happy.jrnet.win -> localhost:3005
  # =========================================================================
  myCaddy.reverseProxies = {
    "happy" = {
      upstream = "thicc-server:${builtins.toString port}";
      proxyOptions = ''
        header_up X-Forwarded-Proto {scheme}
      '';
    };
  };
}
