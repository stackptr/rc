{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.darwin.follows = "nix-darwin";
    agenix.inputs.home-manager.follows = "home-manager";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-homebrew.inputs.nix-darwin.follows = "nix-darwin";
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
    mac-app-util.url = "github:hraban/mac-app-util";
    profile.url = "github:stackptr/profile";
    profile.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    with (import ./lib/hosts.nix inputs); {
      nixosConfigurations = mkNixosHosts [
        {
          hostname = "zeta";
          system = "aarch64-linux";
          allowVpn = true;
        }
        {
          hostname = "glyph";
          system = "x86_64-linux";
          allowVpn = true;
        }
        {
          hostname = "spore";
          system = "x86_64-linux";
          allowVpn = true;
        }
      ];

      darwinConfigurations = mkDarwinHosts [
        {
          hostname = "Rhizome";
          allowVpn = true;
        }
        {
          hostname = "Petrichor";
          allowVpn = false;
        }
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
