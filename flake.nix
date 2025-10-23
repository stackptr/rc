{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    # General
    systems = {
      url = "path:./flake.systems.nix";
      flake = false;
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
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
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
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
    zx-dev = {
      url = "github:stackptr/zx.dev";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    # macOS
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} ({
      config,
      withSystem,
      moduleWithSystem,
      ...
    }: {
      imports = [
        inputs.git-hooks-nix.flakeModule
      ];

      flake = let
        inherit (import ./lib/hosts.nix inputs) mkNixosHost mkDarwinHost;
      in {
        nixosConfigurations = {
          zeta = mkNixosHost {
            hostname = "zeta";
            system = "aarch64-linux";
            username = "mu";
          };
          glyph = mkNixosHost {
            hostname = "glyph";
            system = "x86_64-linux";
            username = "mu";
          };
          spore = mkNixosHost {
            hostname = "spore";
            system = "x86_64-linux";
            username = "mu";
          };
        };

        darwinConfigurations = {
          Rhizome = mkDarwinHost {
            hostname = "Rhizome";
            username = "corey";
          };
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
      };

      systems = import inputs.systems;
      perSystem = {
        pkgs,
        inputs',
        config,
        ...
      }: {
        devShells = {
          default = pkgs.mkShell {
            packages =
              [
                inputs'.agenix.packages.default
                pkgs.cachix
                pkgs.just
              ]
              ++ config.pre-commit.settings.enabledPackages;
            inherit (config.pre-commit) shellHook;
          };
        };
        formatter = let
          inherit (config.pre-commit.settings) package configFile;
        in
          pkgs.writeShellScriptBin "pre-commit-run" ''
            ${pkgs.lib.getExe package} run --all-files --config ${configFile}
          '';
        pre-commit.settings.hooks = {
          alejandra.enable = true;
          nil.enable = true;
          statix.enable = true;
        };
      };
    });
}
