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
    system = "aarch64-linux";
    lib = nixpkgs.lib;
  in {
    nixosConfigurations.zeta = lib.nixosSystem {
      inherit system;
      modules = [
        {environment.systemPackages = [agenix.packages.${system}.default];}
        ./hosts/zeta
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.mu = import ./home;
        }
      ];
    };

    nixosConfigurations.ohm = lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/ohm
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.mu = import ./home;
        }
      ];
    };

    darwinConfigurations."Rhizome" = nix-darwin.lib.darwinSystem {
      modules = [
        ./hosts/Rhizome
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.corey = import ./home;
        }
      ];
    };

    darwinConfigurations."Petrichor" = nix-darwin.lib.darwinSystem {
      modules = [
        ./hosts/Petrichor
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.corey = import ./home;
        }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."Rhizome".pkgs;
  };
}
