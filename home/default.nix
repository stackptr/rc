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
      git = {
        enable = true;
      };
      ssh.enable = true;
      utilities = {
        base.enable = true;
        nix.enable = true;
        system.enable = true;
      };
    }

    (lib.mkIf (hostname != "spore") {
      development = {
        containers.enable = true;
        javascript.enable = true;
      };
      utilities = {
        file.enable = true;
        media.enable = true;
      };
    })
  ];

  home.stateVersion = "23.11";
}
