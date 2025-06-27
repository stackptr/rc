inputs @ {
  self,
  nixpkgs,
  nixpkgs-stable,
  agenix,
  home-manager,
  nix-darwin,
  nix-homebrew,
  homebrew-bundle,
  homebrew-core,
  homebrew-cask,
  mac-app-util,
  zx-dev,
  disko,
  golink,
  ...
}: let
  keys = import ./keys.nix;
  overlays = import ./../overlays;
  validation = import ./validation.nix {inherit (nixpkgs) lib;};

  mkHomeManager = {
    username,
    hostname,
    system,
    enableGuiPackages,
    showBatteryStatus,
  }: let
    pkgs-stable = import nixpkgs-stable {inherit system;};
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
      inherit pkgs-stable enableGuiPackages showBatteryStatus;
    };
  };

  mkNixosHost = {
    hostname,
    system,
    username,
    allowVpn,
  }: let
    validateHostname = validation.validateHostname hostname;
    validateUsername = validation.validateUsername username;
    validateSystem = validation.validateSystem system;
    validateHostFiles = validation.validateHostFiles {
      inherit hostname;
      hostType = "nixos";
    };
  in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs keys username hostname allowVpn;
        pkgs-stable = import nixpkgs-stable {inherit system;};
      };
      modules = [
        {environment.systemPackages = [agenix.packages.${system}.default];}
        disko.nixosModules.disko
        ./../modules/base.nix
        ./../modules/nixos.nix
        ./../modules/secrets-validation.nix
        ./../hosts/${hostname}
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        (mkHomeManager {
          inherit username hostname system;
          enableGuiPackages = false;
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
    allowVpn,
  }: let
    system = "aarch64-darwin";
    validateHostname = validation.validateHostname hostname;
    validateUsername = validation.validateUsername username;
    validateHostFiles = validation.validateHostFiles {
      inherit hostname;
      hostType = "darwin";
    };
  in
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit inputs self keys username hostname allowVpn;
        pkgs-stable = import nixpkgs-stable {inherit system;};
        nixDarwin = nix-darwin;
      };
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        mac-app-util.darwinModules.default
        ./../modules/base.nix
        ./../modules/darwin
        ./../modules/secrets-validation.nix
        ./../hosts/${hostname}
        home-manager.darwinModules.home-manager
        (mkHomeManager {
          inherit username hostname system;
          enableGuiPackages = true;
          showBatteryStatus = true;
        })
        {
          home-manager.sharedModules = [
            mac-app-util.homeManagerModules.default
          ];
        }
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = false;
            user = username;
            taps = {
              "homebrew/homebrew-bundle" = homebrew-bundle;
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
