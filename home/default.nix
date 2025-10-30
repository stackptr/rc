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

  home.packages = with pkgs; [
    coreutils-full
    neofetch
  ];

  rc = lib.mkMerge [
    {
      git = {
        enable = true;
        enableHubWrapper = true;
        enableInteractiveRebase = true;
      };
      utilities = {
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
