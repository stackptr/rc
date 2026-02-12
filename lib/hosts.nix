inputs @ {
  self,
  nixpkgs,
  agenix,
  home-manager,
  nix-darwin,
  nix-homebrew,
  homebrew-core,
  homebrew-cask,
  zx-dev,
  disko,
  golink,
  ...
}: let
  keys = import ./keys.nix;
  overlays = import ./../overlays;

  mkHomeManager = {
    username,
    hostname,
    system,
    showBatteryStatus,
  }: let
    hostHomePath = ./../hosts/${hostname}/home.nix;
    hostHomeConfig =
      if builtins.pathExists hostHomePath
      then hostHomePath
      else null;
  in {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${username} = {...}: {
      imports =
        [
          ./../modules/home
          ./../home
        ]
        ++ nixpkgs.lib.optionals (hostHomeConfig != null) [hostHomeConfig];
    };
    home-manager.extraSpecialArgs = {
      inherit hostname showBatteryStatus;
    };
  };

  mkNixosHost = {
    hostname,
    system,
    username,
  }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs keys username hostname;
      };
      modules = [
        {environment.systemPackages = [agenix.packages.${system}.default];}
        disko.nixosModules.disko
        ./../modules/base
        ./../modules/nixos
        ./../hosts/${hostname}
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        (mkHomeManager {
          inherit username hostname system;
          showBatteryStatus = false;
        })
        {
          nixpkgs.overlays = overlays;
        }
        golink.nixosModules.default
        zx-dev.nixosModules.default
      ];
    };

  mkDarwinHost = {
    hostname,
    username,
  }: let
    system = "aarch64-darwin";
  in
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit inputs self keys username hostname;
        nixDarwin = nix-darwin;
      };
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        ./../modules/base
        ./../modules/darwin
        ./../hosts/${hostname}
        home-manager.darwinModules.home-manager
        (mkHomeManager {
          inherit username hostname system;
          showBatteryStatus = true;
        })
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = false;
            user = username;
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };
            mutableTaps = false;
          };
        }
        {
          nixpkgs.overlays = overlays;
        }
      ];
    };
in {
  inherit mkNixosHost mkDarwinHost;
}
