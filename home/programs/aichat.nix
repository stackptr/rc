_: let
  model = "qwen3.8-27b-mtplx-optimized-quality";
in {
  programs.aichat = {
    enable = true;
    settings = {
      model = "stroma:${model}";
      clients = [
        {
          type = "openai-compatible";
          name = "stroma";
          api_base = "https://stroma.note-iwato.ts.net/v1";
          models = [{name = model;}];
        }
      ];
    };
  };
}
