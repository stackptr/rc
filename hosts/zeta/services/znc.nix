{
  config,
  pkgs,
  ...
}: {
  age.secrets.znc-conf.file = ./../secrets/znc-conf.age;
  services.znc = {
    enable = true;
    mutable = false;
    useLegacyConfig = false;
    openFirewall = true;
    modulePackages = [pkgs.zncModules.palaver];
    configFile = config.age.secrets.znc-conf.path;
  };
}
