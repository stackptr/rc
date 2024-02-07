{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    with (import ./lib/hosts.nix inputs); {
      nixosConfigurations = mkNixosHosts [
        {
          hostname = "zeta";
          system = "aarch64-linux";
        }
        {
          hostname = "ohm";
          system = "x86_64-linux";
        }
      ];

      darwinConfigurations = mkDarwinHosts [
        "Rhizome"
        "Petrichor"
      ];
    };
}
