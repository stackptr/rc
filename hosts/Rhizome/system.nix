{
  config,
  pkgs,
  ...
}: {
  users.users.corey = {
    home = "/Users/corey";
  };

  # TODO: Set Git commit hash for darwin-version.
  #system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 4;
  nixpkgs.hostPlatform = "aarch64-darwin";
}
