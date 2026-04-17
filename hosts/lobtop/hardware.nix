{
  config,
  pkgs,
  ...
}: {
  users.users.corey = {
    home = "/Users/corey";
  };
  system.primaryUser = "corey";

  networking.hostName = "LOB-MG2QJH49W7";

  system.stateVersion = 5;
  nixpkgs.hostPlatform = "aarch64-darwin";
}
