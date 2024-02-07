{
  nixpkgs,
  agenix,
  home-manager,
  nix-darwin,
  profile,
  ...
}: let
  baseHomeManager = username: {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${username} = import ./../home;
  };
  nixosHomeManager = baseHomeManager "mu";
  nixosHost = {
    system,
    hostname,
  }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit profile;};
      modules = [
        {environment.systemPackages = [agenix.packages.${system}.default];}
        ./../hosts/${hostname}
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        nixosHomeManager
      ];
    };
  darwinHomeManager = baseHomeManager "corey";
  darwinHost = {hostname, ...}:
    nix-darwin.lib.darwinSystem {
      modules = [
        ./../hosts/${hostname}
        home-manager.darwinModules.home-manager
        darwinHomeManager
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
