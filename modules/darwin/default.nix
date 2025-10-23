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

  environment.systemPackages = with pkgs; [
    chatgpt
    cinny-desktop
    claude-desktop
    github-desktop
    gitify
    m-cli
    mas
    mochi
    slack
    the-unarchiver
    whatsapp-for-mac
    zoom-us
  ];

  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Auto upgrade nix package and the daemon service.
  nix.enable = true;
  nix.package = pkgs.nix;
}
