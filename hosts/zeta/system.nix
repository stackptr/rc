{
  config,
  pkgs,
  keys,
  ...
}: {
  security.sudo.wheelNeedsPassword = false;

  users = {
    mutableUsers = false;
    users.mu = {
      isNormalUser = true;
      extraGroups = ["wheel" "docker"];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        keys.Petrichor
        keys.Rhizome
      ];
    };
    users.root.openssh.authorizedKeys.keys = [keys.Petrichor keys.Rhizome];
  };

  system.stateVersion = "23.11";
}
