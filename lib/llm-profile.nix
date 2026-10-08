# Concatenates llm-profile modules into the bundles each surface reads.
llm-profile: let
  read = f: builtins.readFile "${llm-profile}/${f}";
  bundle = files: builtins.concatStringsSep "\n\n" (map read files);
in {
  chat = bundle ["core.md" "chat.md"];
  agent = bundle ["core.md" "agent.md"];
  skills = "${llm-profile}/skills";
}
