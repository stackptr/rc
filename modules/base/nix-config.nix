# Nix-specific configuration settings
{
  inputs,
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  nix = {
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [username];
    };
  };

  programs.zsh.enable = true;
}
