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

    (lib.mkIf (hostname != "loam") {
      development = {
        containers.enable = true;
        javascript.enable = true;
      };
      git.enableJujutsu = true;
      utilities = {
        file.enable = true;
        media.enable = true;
      };
    })
  ];

  home.stateVersion = "23.11";
}
