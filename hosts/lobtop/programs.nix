{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    m-cli
    mas
    the-unarchiver
  ];

  homebrew = {
    enable = true;
    # N.B.: Removed entries in `masApps` require manual uninstallation
    masApps = {
    };
  };
}
