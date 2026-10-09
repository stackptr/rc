{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./dock.nix
    ./hardware.nix
    ./monitoring.nix
    ./programs.nix
  ];

  rc.darwin.defaults = {
    fonts = true;
    homebrew = true;
    security = true;
    system = true;
  };
}
