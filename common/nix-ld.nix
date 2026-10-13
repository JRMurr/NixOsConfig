{ config, lib, ... }:
{
  # Lets prebuilt generic-Linux binaries run, e.g. the CLI Claude Desktop
  # downloads into ~/.claude/remote/ccd-cli when using this host as a remote.
  config = lib.mkIf config.myOptions.nixLd.enable {
    programs.nix-ld.enable = true;
  };
}
