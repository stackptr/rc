{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./dock.nix
    ./hardware.nix
    ./programs.nix
  ];

  rc.darwin.defaults = {
    fonts = true;
    homebrew = true;
    security = true;
    system = true;
  };

  rc.darwin.smb-mount = {
    enable = true;
    smbPath = "smb://glyph/Media";
  };
}
