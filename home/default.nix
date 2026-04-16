{
  config,
  pkgs,
  lib,
  lightweight,
  ...
}: {
  imports = [
    ./programs
  ];

  age.identityPaths = [
    "${config.home.homeDirectory}/.ssh/id_ed25519_agenix"
  ];

  rc = lib.mkMerge [
    {
      development.ai.enable = true;
      editor.enable = true;
      git.enable = true;
      ssh.enable = true;
      utilities = {
        base.enable = true;
        nix.enable = true;
        system.enable = true;
      };
    }

    (lib.mkIf (!lightweight) {
      development = {
        containers.enable = true;
        javascript.enable = true;
      };
      graphite.enable = true;
      jujutsu.enable = true;
      utilities = {
        file.enable = true;
        media.enable = true;
      };
    })
  ];

  home.stateVersion = "23.11";
}
