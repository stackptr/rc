{lib, ...}: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [
      "100.100.100.100" # Tailscale
      "8.8.8.8"
      "1.1.1.1"
    ];
    search = ["rove-duck.ts.net"];
    defaultGateway = "146.190.112.1";
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
            address = "146.190.126.122";
            prefixLength = 20;
          }
          {
            address = "10.48.0.5";
            prefixLength = 16;
          }
        ];
        ipv6.addresses = [
          {
            address = "fe80::bc52:eff:fee9:ae66";
            prefixLength = 64;
          }
        ];
        ipv4.routes = [
          {
            address = "146.190.112.1";
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
            address = "10.124.0.2";
            prefixLength = 20;
          }
        ];
        ipv6.addresses = [
          {
            address = "fe80::4f8:bfff:fee0:5a0e";
            prefixLength = 64;
          }
        ];
      };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="be:52:0e:e9:ae:66", NAME="eth0"
    ATTR{address}=="06:f8:bf:e0:5a:0e", NAME="eth1"
  '';
}
