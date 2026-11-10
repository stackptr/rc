{config, ...}: {
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

  # Work's Cloudflare Gateway intercepts TLS (e.g. cache.zx.dev) with this CA.
  # MDM trusts it in the keychain, but the Nix daemon and nixpkgs' curl and git
  # read /etc/ssl/certs/ca-certificates.crt instead. Expires 2029-12-11; if IT
  # rotates it, re-export with
  # `security find-certificate -c "Gateway CA - Cloudflare Managed G2" -p /Library/Keychains/System.keychain`.
  security.pki.certificateFiles = [./cloudflare-gateway-ca.pem];

  # A user secret, read by home-manager through osConfig. Decrypted at boot
  # with sshd's host key (hosts/lobtop/key.pub).
  age.secrets.otel-token = {
    file = ./secrets/otel-token.age;
    owner = config.system.primaryUser;
  };
}
