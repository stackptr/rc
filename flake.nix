{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
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
          ./hosts/${hostname}
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.mu = import ./home;
          }
        ];
      };
    darwinHost = {hostname, ...}:
      nix-darwin.lib.darwinSystem {
        modules = [
          ./hosts/${hostname}
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.corey = import ./home;
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
  in {
    nixosConfigurations = mkHosts nixosHost [
      {
        hostname = "zeta";
        system = "aarch64-linux";
      }
      {
        hostname = "ohm";
        system = "x86_64-linux";
      }
    ];

    darwinConfigurations = mkHosts darwinHost [
      {
        hostname = "Rhizome";
      }
      {
        hostname = "Petrichor";
      }
    ];
  };
}
