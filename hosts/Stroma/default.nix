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

  # Remote Login, open only to the YubiKeys. sshd's host key is also Stroma's
  # agenix identity (hosts/Stroma/key.pub).
  services.openssh = {
    enable = true;
    extraConfig = ''
      PasswordAuthentication no
      KbdInteractiveAuthentication no
    '';
  };
  users.users.${config.system.primaryUser}.openssh.authorizedKeys.keys =
    map (k: "verify-required ${k}") keys.yubikeys ++ [keys.secureEnclave.Rhizome];

  # Stroma serves oMLX and is scraped by Prometheus, so the system never sleeps
  # (a sleeping Mac drops node, mactop, alloy and omlx and trips Gatus). Display
  # sleep is unaffected. pmset rather than power.sleep.computer, which goes
  # through systemsetup and needs Full Disk Access.
  system.activationScripts.postActivation.text = ''
    /usr/bin/pmset -a sleep 0
    /usr/bin/pmset -a womp 1
  '';

  # A user secret, read by home-manager through osConfig
  age.secrets.aichat-env = {
    file = ../../home/secrets/aichat-env.age;
    owner = username;
  };
}
