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
      environmentFile = config.age.secrets.wireless.path;
      networks.Ansible.psk = "@PSK_ANSIBLE@";
      interfaces = ["wlan0"];
    };
  };
}
