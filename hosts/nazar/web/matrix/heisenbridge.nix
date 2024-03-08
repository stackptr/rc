{
  config,
  pkgs,
  ...
}: let
  cfg = config.services.heisenbridge;

  pkg = config.services.heisenbridge.package;
  bin = "${pkg}/bin/heisenbridge";

  registrationFile = "/var/lib/heisenbridge/registration.yml";
  # JSON is a proper subset of YAML
  bridgeConfig = builtins.toFile "heisenbridge-registration.yml" (builtins.toJSON {
    id = "heisenbridge";
    url = cfg.registrationUrl;
    # Don't specify as_token and hs_token
    rate_limited = false;
    sender_localpart = "heisenbridge";
    namespaces = cfg.namespaces;
  });
in
{
  services.heisenbridge = {
    enable = true;
    homeserver = "http://localhost:8008";
    owner = "@corey:zx.dev";
  };
  # Override systemd service for Dendrite
  systemd.services.heisenbridge.before = [ "dendrite.service" ];
  systemd.services.heisenbridge.preStart = ''
    umask 077
    set -e -u -o pipefail
  
    if ! [ -f "${registrationFile}" ]; then
      # Generate registration file if not present (actually, we only care about the tokens in it)
      ${bin} --generate --config-compat ${registrationFile}
    fi
  
    # Overwrite the registration file with our generated one (the config may have changed since then),
    # but keep the tokens. Two step procedure to be failure safe
    ${pkgs.yq}/bin/yq --slurp \
      '.[0] + (.[1] | {as_token, hs_token})' \
      ${bridgeConfig} \
      ${registrationFile} \
      > ${registrationFile}.new
    mv -f ${registrationFile}.new ${registrationFile}
  
    # Grant Dendrite access to the registration
    if ${pkgs.getent}/bin/getent group dendrite > /dev/null; then
      chgrp -v dendrite ${registrationFile}
      chmod -v g+r ${registrationFile}
    fi
  '';
}
