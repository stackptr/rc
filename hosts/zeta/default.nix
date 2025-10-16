{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
    ./wireless.nix
    ./services
  ];

  systemd.package = pkgs.systemd;
  environment.systemPackages = with pkgs; let
    systemd-link = pkgs.runCommand "systemd-stdio-bridge-link" {} ''
      mkdir -p $out/lib/systemd
      ln -s ${pkgs.systemd}/bin/systemd-stdio-bridge \
            $out/lib/systemd/systemd-stdio-bridge
    '';
  in [
    systemd
    systemd-link
  ];

  environment.pathsToLink = ["/share/zsh"];
  system.stateVersion = "23.11";
}
