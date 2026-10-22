{
  config,
  pkgs,
  username,
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

  # A laptop on networks I don't control, with nothing that needs to accept
  # connections. Apple-signed and Developer ID-signed apps are still allowed
  # (macOS defaults), so AirDrop and the like keep working. Stroma stays
  # unmanaged: its Nix-built exporters are only ad-hoc signed, and glyph
  # scrapes them.
  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;
  };

  # A user secret, read by home-manager through osConfig. Decrypted at boot
  # with sshd's host key (hosts/Rhizome/key.pub).
  age.secrets.aichat-env = {
    file = ../../home/secrets/aichat-env.age;
    owner = username;
  };
}
