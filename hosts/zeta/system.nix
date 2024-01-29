{
  config,
  pkgs,
  ...
}: {
  age.secrets.userpassword.file = ./secrets/userpassword.age;

  security.sudo.wheelNeedsPassword = false;

  users = {
    mutableUsers = false;
    users.mu = {
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.userpassword.path;
      extraGroups = ["wheel" "docker"];
      shell = pkgs.zsh;
    };
    users.root.initialPassword = "password";
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "23.11";
}
