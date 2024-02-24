{
  self,
  config,
  pkgs,
  ...
}: {
  security.pam.enableSudoTouchIdAuth = true;

  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;
}
