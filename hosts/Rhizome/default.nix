{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./dock.nix
    ./hardware.nix
    ./programs.nix
  ];
}
