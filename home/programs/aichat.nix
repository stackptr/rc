{config, ...}: {
  age.identityPaths = [
    "${config.home.homeDirectory}/.ssh/id_ed25519_agenix"
  ];

  age.secrets.aichat-env = {
    file = ../secrets/aichat-env.age;
  };

  programs.aichat = {
    enable = true;
    settings = {
      model = "claude:claude-sonnet-4-20250514";
      clients = [
        {type = "claude";}
      ];
    };
  };

  programs.zsh.sessionVariables = {
    AICHAT_ENV_FILE = config.age.secrets.aichat-env.path;
  };
}
