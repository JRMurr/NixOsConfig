{ config, ... }: { imports = [ ./grafana.nix ./loki.nix ./prometheus.nix ]; }
