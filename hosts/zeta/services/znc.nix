{
  config,
  pkgs,
  ...
}: {
  age.secrets.znc-conf = {
    file = ./../secrets/znc-conf.age;
    owner = config.services.znc.user;
    inherit (config.services.znc) group;
  };
  services.znc = {
    enable = false;
    mutable = false;
    useLegacyConfig = false;
    openFirewall = true;
    modulePackages = [pkgs.zncModules.palaver];
    # N.B.: Use services.znc.config after secrets can be interspersed
    configFile = config.age.secrets.znc-conf.path;
  };
}
