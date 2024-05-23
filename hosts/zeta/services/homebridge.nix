{
  config,
  pkgs,
  ...
}: {
  users.users.mu.extraGroups = ["docker"];
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {
    homebridge = {
      image = "homebridge/homebridge@sha256:294a8041d92d8db3d44db0dda9cb565c31d567a704f57b8866241c3cd2cbd3f3";
      ports = [
        "8581:8581"
      ];
      volumes = [
        "homebridge_data:/homebridge"
        "/var/run/dbus:/var/run/dbus"
        "/var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket"
      ];
      autoStart = true;
      extraOptions = [
        "--network=host"
      ];
    };
  };
}
