{
  config,
  pkgs,
  ...
}: {
  users.users.corey = {
    home = "/Users/corey";
  };

  system.stateVersion = 4;
  nixpkgs.hostPlatform = "aarch64-darwin";
}
