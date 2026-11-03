{
  config,
  keys,
  pkgs,
  username,
  ...
}: {
  imports = [
    ./dock.nix
    ./hardware.nix
    ./monitoring.nix
    ./omlx.nix
    ./programs.nix
  ];

  rc.darwin.defaults = {
    fonts = true;
    homebrew = true;
    security = true;
    system = true;
  };

  # Remote Login, open only to the YubiKeys, Rhizome and the iPhones. sshd's
  # host key is also Stroma's agenix identity (hosts/Stroma/key.pub).
  services.openssh = {
    enable = true;
    extraConfig = ''
      PasswordAuthentication no
      KbdInteractiveAuthentication no
    '';
  };
  users.users.${config.system.primaryUser}.openssh.authorizedKeys.keys =
    map (k: "verify-required ${k}") keys.yubikeys
    ++ [keys.secureEnclave.Rhizome]
    ++ builtins.attrValues keys.phones;

  # A user secret, read by home-manager through osConfig
  age.secrets.aichat-env = {
    file = ../../home/secrets/aichat-env.age;
    owner = username;
  };
}
