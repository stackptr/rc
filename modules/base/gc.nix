# Nix store garbage collection
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
}
