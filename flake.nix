{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, agenix, home-manager, ... }:
  let
    system = "aarch64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config = { 
        # allowUnfree = true;
      };
    };
    lib = nixpkgs.lib;
  in {
    nixosConfigurations.zeta = lib.nixosSystem {
      inherit system;
      modules = [
        { environment.systemPackages = [ agenix.packages.${system}.default ]; }
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
  };
}
