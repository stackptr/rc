{
  self,
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  imports = [
    ./programs
    ./system
    ./rc.nix
  ];

  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Auto upgrade nix package and the daemon service.
  nix.enable = true;
  nix.package = pkgs.nix;
}
