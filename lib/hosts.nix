{
  nixpkgs,
  agenix,
  home-manager,
  nix-darwin,
  ...
}: {
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
  mkHosts = f: hosts:
    builtins.listToAttrs (map
      (host: {
        name = host.hostname;
        value = f host;
      })
      hosts);
}
