{
  pkgs-stable,
  lib,
  ...
}: {
  programs.awscli = {
    enable = true;
    package = pkgs-stable.awscli2;
    settings = {
      "profile freckle-dev" = {
        sso_account_id = "539282909833";
        sso_role_name = "AWSRENFreckleEngineer";
        region = "us-east-1";
        sso_session = "freckle-dev-engineers";
      };
      "profile freckle-prod" = {
        sso_account_id = "853032795538";
        sso_role_name = "AWSRENFreckleEngineer";
        region = "us-east-1";
        sso_session = "freckle-dev-engineers";
      };
      "sso-session freckle-dev-engineers" = {
        sso_start_url = "https://d-90675613ab.awsapps.com/start";
        sso_region = "us-east-1";
        sso_registration_scopes = "sso:account:access";
      };
    };
  };
}
