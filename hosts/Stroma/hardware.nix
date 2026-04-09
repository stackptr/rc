{
  config,
  pkgs,
  ...
}: {
  users.users.corey = {
    home = "/Users/corey";
  };
  system.primaryUser = "corey";

  system.stateVersion = 5;
  nixpkgs.hostPlatform = "aarch64-darwin";
}
