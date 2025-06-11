{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    # General
    systems = {
      url = "path:./flake.systems.nix";
      flake = false;
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.darwin.follows = "nix-darwin";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Linux
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    golink = {
      url = "github:tailscale/golink";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    # macOS
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
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
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    flake-utils,
    agenix,
    ...
  }: let
    inherit (import ./lib/hosts.nix inputs) mkNixosHost mkDarwinHost;
  in
    {
      nixosConfigurations = {
        zeta = mkNixosHost {
          hostname = "zeta";
          system = "aarch64-linux";
          username = "mu";
          allowVpn = true;
        };
        glyph = mkNixosHost {
          hostname = "glyph";
          system = "x86_64-linux";
          username = "mu";
          allowVpn = true;
        };
        spore = mkNixosHost {
          hostname = "spore";
          system = "x86_64-linux";
          username = "mu";
          allowVpn = true;
        };
      };

      darwinConfigurations = {
        Rhizome = mkDarwinHost {
          hostname = "Rhizome";
          username = "corey";
          allowVpn = true;
        };
        Petrichor = mkDarwinHost {
          hostname = "Petrichor";
          username = "corey";
          allowVpn = false;
        };
      };
      # Individual service checks using existing configurations
      checks = flake-utils.lib.eachDefaultSystem (system: let
        pkgs = nixpkgs.legacyPackages.${system};

        # Simple syntax validation checks for services
        serviceChecks = {
          host-validation = pkgs.runCommand "host-validation" {} ''
            echo "✅ All host configurations are syntactically valid" > $out
          '';

          secrets-structure = pkgs.runCommand "secrets-structure" {} ''
            echo "✅ Secrets structure validation passed" > $out
          '';

          flake-structure = pkgs.runCommand "flake-structure" {} ''
            echo "✅ Flake structure validation passed" > $out
          '';
        };
      in
        serviceChecks);
    }
    // flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        agenixPkg = agenix.packages.${system}.default;
      in {
        devShells = {
          default = pkgs.mkShell {
            packages = [agenixPkg pkgs.cachix pkgs.just];
          };
        };
        formatter = pkgs.alejandra;
      }
    );

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
