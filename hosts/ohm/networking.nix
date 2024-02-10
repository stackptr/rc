{lib, ...}: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [
      "8.8.8.8"
    ];
    defaultGateway = "143.198.144.1";
    defaultGateway6 = {
      address = "";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          {
            address = "143.198.154.166";
            prefixLength = 20;
          }
          {
            address = "10.48.0.6";
            prefixLength = 16;
          }
        ];
        ipv6.addresses = [
          {
            address = "fe80::ec9c:6fff:fee8:433e";
            prefixLength = 64;
          }
        ];
        ipv4.routes = [
          {
            address = "143.198.144.1";
            prefixLength = 32;
          }
        ];
        ipv6.routes = [
          {
            address = "";
            prefixLength = 128;
          }
        ];
      };
      eth1 = {
        ipv4.addresses = [
          {
            address = "10.124.0.3";
            prefixLength = 20;
          }
        ];
        ipv6.addresses = [
          {
            address = "fe80::5493:8fff:fe1b:ce84";
            prefixLength = 64;
          }
        ];
      };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="ee:9c:6f:e8:43:3e", NAME="eth0"
    ATTR{address}=="56:93:8f:1b:ce:84", NAME="eth1"
  '';
}
