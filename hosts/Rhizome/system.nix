{ config, pkgs, ... }: {
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  nix.settings.experimental-features = "nix-command flakes";
  
  # TODO: Set Git commit hash for darwin-version.
  #system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 4;
  nixpkgs.hostPlatform = "aarch64-darwin";
}
