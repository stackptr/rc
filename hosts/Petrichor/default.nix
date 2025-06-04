{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
  ];
  system.defaults.dock = {
    tilesize = 49;
    largesize = 92;
  };
}
