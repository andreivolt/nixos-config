{ config, ... }:
let
  p = config.sops.placeholder;
in {
  sops.templates."dictate.env" = {
    owner = "andrei";
    content = ''
      DEEPGRAM_API_KEY=${p."deepgram/api_key"}
      GROQ_API_KEY=${p."groq/api_key"}
      FIREWORKS_API_KEY=${p."fireworks/api_key"}
    '';
  };
}
