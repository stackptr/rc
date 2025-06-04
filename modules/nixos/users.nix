# User management configuration for NixOS
{
  lib,
  config,
  pkgs,
  keys,
  ...
}: {
  users = {
    mutableUsers = false;
    users.mu = {
      description = "Corey";
      isNormalUser = true;
      extraGroups = ["wheel"];
      shell = pkgs.zsh;
    };
  };
}
