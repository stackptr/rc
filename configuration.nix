{ config, pkgs, lib, ... }: {
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };
  
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };
  
  networking = {
    hostName = "zeta";
    wireless = {
      enable = true;
      environmentFile = "/home/mu/wireless.env";
      networks.Ansible.psk = "@PSK_ANSIBLE@";
      interfaces = [ "wlan0" ];
    };
  };
  
  environment.systemPackages = with pkgs; [
    vim
    tailscale
  ];
  
  services.openssh.enable = true;
  services.tailscale.enable = true;
  services.samba = {
    enable = true;
    securityType = "user";
    openFirewall = true;
    invalidUsers = [];
    shares = {
      zeta = {
        path = "/";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "root";
        "force group" = "root";
      };
    };
  };

  programs.mosh.enable = true;
  programs.git = {
    enable = true;
    config = {
      user = {
        name = "✿ corey";
        email = "corey@x64.co";
      };
    };
  };

  virtualisation.docker.enable = true;
  systemd.services.run-portainer = {
    path = [ pkgs.docker ];
    script = ''
      docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always --pull=always  -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ee:latest
    '';
    wantedBy = ["multi-user.target"];
    after = ["docker.service" "docker.socket"];
  };
  
  users = {
    mutableUsers = false;
    users.mu = {
      isNormalUser = true;
      password = "password";
      extraGroups = [ "wheel" "docker" ];
    };
    users.root.initialPassword = "password";
  };
  
  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "23.11";
}
