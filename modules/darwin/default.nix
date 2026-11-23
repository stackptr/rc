{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./programs
    ./system
    ./rc.nix
  ];

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Auto upgrade nix package and the daemon service.
  nix.enable = true;
  nix.package = pkgs.nix;
  nix.settings.trusted-users = [config.system.primaryUser];
}
