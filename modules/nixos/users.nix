# User management configuration for NixOS
{
  lib,
  config,
  pkgs,
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

  nix.settings.trusted-users = ["mu"];
}
