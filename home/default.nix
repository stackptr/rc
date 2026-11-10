{
  imports = [
    ./programs
  ];

  rc = {
    development.ai.enable = true;
    editor.enable = true;
    git.enable = true;
    ssh.enable = true;
    utilities = {
      base.enable = true;
      nix.enable = true;
      system.enable = true;
    };
  };

  home.stateVersion = "23.11";
}
