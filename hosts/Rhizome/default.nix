{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
  ];
  system.defaults.dock = {
    tilesize = 42;
    largesize = 86;
  };
}
