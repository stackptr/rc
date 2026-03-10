{
  config,
  pkgs,
  ...
}: {
  services.atuin = {
    enable = true;
    host = "0.0.0.0";
    port = 8889;
    openRegistration = true;
  };
}
