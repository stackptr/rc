{pkgs, ...}: {
  rc.gpg.enable = true;

  programs.claude-code.settings.env = {
    CLAUDE_CODE_USE_BEDROCK = "1";
    AWS_REGION = "us-west-2";
    AWS_PROFILE = "bedrock";
    ANTHROPIC_DEFAULT_SONNET_MODEL = "us.anthropic.claude-sonnet-4-6";
    ANTHROPIC_DEFAULT_HAIKU_MODEL = "us.anthropic.claude-haiku-4-5-20251001-v1:0";
  };
}
