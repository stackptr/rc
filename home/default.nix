{
  pkgs,
  lib,
  hostname,
  ...
}: {
  imports = [
    ./programs
    ./services.nix
  ];

  rc = lib.mkMerge [
    {
      editor.enable = true;
      git.enable = true;
      ssh.enable = true;
      utilities = {
        base.enable = true;
        nix.enable = true;
        system.enable = true;
      };
    }

    (lib.mkIf (hostname != "spore" && hostname != "zeta") {
      development = {
        ai.enable = true;
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
