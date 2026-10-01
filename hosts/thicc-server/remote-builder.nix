{
  # Build host for the Steam Frame, which is aarch64 and has no business
  # compiling anything on battery. See hosts/frame/README.md.
  #
  # qemu-user through binfmt, so these builds are emulated and slower per core
  # than the native x86 ones. Implies nix.settings.extra-platforms +=
  # aarch64-linux (boot.binfmt.addEmulatedSystemsToNixSandbox defaults true),
  # which is what makes the frame's `systems = [ "aarch64-linux" ]` builder entry
  # match.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
