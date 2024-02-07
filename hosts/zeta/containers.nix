{
  config,
  pkgs,
  profile,
  ...
}: {
  containers.profile = {
    autoStart = true;
    config = { config, pkgs, ... }:
    let
      profileApp = profile.packages.${pkgs.system}.default;
    in {
        environment.systemPackages = [
          profileApp
        ];
        systemd.services.run-profile = {
          wantedBy = ["multi-user.target"];
          serviceConfig.ExecStart = profileApp;
        };
        networking.firewall.allowedTCPPorts = [ 80 ];
        system.stateVersion = "24.05";
    };
  };
}
