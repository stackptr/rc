{
  config,
  pkgs,
  ...
}: {
  services.homebridge = {
    enable = true;
  };
}
