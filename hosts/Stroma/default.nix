{
  config,
  keys,
  pkgs,
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

  # Remote Login, open only to Rhizome. sshd's host key is also Stroma's
  # agenix identity (hosts/Stroma/key.pub).
  services.openssh = {
    enable = true;
    extraConfig = ''
      PasswordAuthentication no
      KbdInteractiveAuthentication no
    '';
  };
  users.users.${config.system.primaryUser}.openssh.authorizedKeys.keys = [keys.Rhizome];
}
