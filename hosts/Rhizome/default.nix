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

  # A user secret, read by home-manager through osConfig. Decrypted at boot
  # with sshd's host key (hosts/Rhizome/key.pub).
  age.secrets.aichat-env = {
    file = ../../home/secrets/aichat-env.age;
    owner = username;
  };
}
