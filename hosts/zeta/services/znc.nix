{
  config,
  pkgs,
  ...
}: {
  services.znc = {
    enable = true;
    mutable = false;
    useLegacyConfig = false;
    openFirewall = true;
    modulePackages = [pkgs.zncModules.palaver];
    config = {
      LoadModule = ["webadmin" "adminlog" "palaver"];
      User.mu = {
        Admin = true;
        Nick = "mu";
        AltNick = "mu`";
        LoadModule = ["chansaver" "controlpanel"];
        Network.libera = {
          Server = "irc.libera.chat +6697";
          Nick = "byte";
          LoadModule = ["simple_away" "nickserv"];
        };
        Pass.password = {
          Method = "sha256";
          Hash = "ef276a8b95bdfaaaeb54bede234d9d55eb42c4bf7589355007453cba94aae463";
          Salt = ",B48aQBMH?y58/3oUp?z";
        };
      };
    };
  };
}
