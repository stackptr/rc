{
  config,
  pkgs,
  ...
}: {
  age.secrets.wireless.file = ./secrets/wireless.age;

  networking = {
    hostName = "zeta";
    wireless = {
      enable = true;
      secretsFile = config.age.secrets.wireless.path;
      networks.Ansible.pskRaw = "ext:psk_ansible";
    };
  };

  services.resolved.enable = true;
  systemd.services.wpa_supplicant.enable = false;
}
