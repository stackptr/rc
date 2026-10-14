{config, ...}: let
  model = "Qwen3.8-27B-MTPLX-Optimized-Quality";
in {
  # STROMA_API_KEY=<oMLX sub-key>; aichat reads <CLIENT>_API_KEY from it
  age.secrets.aichat-env = {
    file = ../secrets/aichat-env.age;
  };

  programs.aichat = {
    enable = true;
    settings = {
      model = "stroma:${model}";
      clients = [
        {
          # oMLX on Stroma (hosts/Stroma/omlx.nix)
          type = "openai-compatible";
          name = "stroma";
          api_base = "http://stroma.note-iwato.ts.net:8000/v1";
          models = [{name = model;}];
        }
      ];
    };
  };

  programs.zsh.sessionVariables = {
    AICHAT_ENV_FILE = config.age.secrets.aichat-env.path;
  };
}
