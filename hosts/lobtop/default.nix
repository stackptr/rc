{username, ...}: {
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
  # with sshd's host key (hosts/lobtop/key.pub).
  age.secrets.otel-token = {
    file = ./secrets/otel-token.age;
    owner = username;
  };
}
