# Nix store garbage collection and boot entry limits
{
  lib,
  pkgs,
  ...
}: {
  nix.gc =
    {
      automatic = true;
      options = "--delete-older-than 30d";
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      dates = "weekly";
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      interval = {Weekday = 0;};
    };

  boot.loader.systemd-boot.configurationLimit = lib.mkIf pkgs.stdenv.isLinux 10;
}
