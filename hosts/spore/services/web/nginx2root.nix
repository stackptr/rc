# Mitigation for nginx2root (https://nginx.org/en/security_advisories.html):
# CVE-2026-123007 and CVE-2026-123633 are in nginx's HTTP/2 code (1.9.5 to
# 1.31.8; fixed in 1.30.7), and nixos-unstable still ships 1.30.6. Remove this
# file once spore runs 1.30.7 or later.
{
  lib,
  pkgs,
  ...
}: {
  # NixOS turns HTTP/2 on for every TLS vhost by default; this turns it off
  # for all of them, including ones other modules declare.
  options.services.nginx.virtualHosts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      config.http2 = lib.mkForce false;
    });
  };

  # Xint chained the nginx bugs with a kernel SCTP flaw to get root. spore
  # doesn't use SCTP, so stop the module from loading at all (a plain
  # blacklist would still allow `modprobe sctp`).
  config.boot.extraModprobeConfig = ''
    install sctp ${pkgs.coreutils}/bin/false
  '';
}
