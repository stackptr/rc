{pkgs, ...}: {
  programs.awscli = {
    enable = true;
    settings = {
      freckle-dev = {
        sso_start_url = "https://d-90675613ab.awsapps.com/start";
        sso_region = "us-east-1";
        sso_account_id = "539282909833";
        sso_role_name = "Freckle-Dev-Engineers";
        region = "us-east-1";
      };
      freckle-prod = {
        sso_start_url = "https://d-90675613ab.awsapps.com/start";
        sso_region = "us-east-1";
        sso_account_id = "853032795538";
        sso_role_name = "FrecklePlatform";
        region = "us-east-1";
      };
    };
  };
}
