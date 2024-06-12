{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    profile.url = "github:stackptr/profile";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    with (import ./lib/hosts.nix inputs); {
      nixosConfigurations = mkNixosHosts [
        {
          hostname = "zeta";
          system = "aarch64-linux";
        }
        {
          hostname = "nazar";
          system = "x86_64-linux";
        }
      ];

      darwinConfigurations = mkDarwinHosts [
        "Rhizome"
        "Petrichor"
      ];
    };

  nixConfig = {
    experimental-features = ["nix-command" "flakes"];
    extra-substituters = [
      "https://stackptr.cachix.org"
    ];
    extra-trusted-public-keys = [
      "stackptr.cachix.org-1:5e2q7OxdRdAtvRmHTeogpgJKzQhbvFqNMmCMw71opZA="
    ];
  };
}
