{
  nixpkgs,
  agenix,
  home-manager,
  nix-darwin,
  ...
}: let
  nixosHost = {
    system,
    hostname,
  }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        {environment.systemPackages = [agenix.packages.${system}.default];}
        ./../hosts/${hostname}
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.mu = import ./../home;
        }
      ];
    };
  darwinHost = {hostname, ...}:
    nix-darwin.lib.darwinSystem {
      modules = [
        ./../hosts/${hostname}
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.corey = import ./../home;
        }
      ];
    };
  mkHosts = f: hostEntries:
    builtins.listToAttrs (map
      (host: {
        name = host.hostname;
        value = f host;
      })
      hostEntries);
  hostEntry = name: {hostname = name;};
in {
  mkNixosHosts = mkHosts nixosHost;
  mkDarwinHosts = names: mkHosts darwinHost (map hostEntry names);
}
