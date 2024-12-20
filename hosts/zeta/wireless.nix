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
      interfaces = ["wlan0"];
    };
  };
}
