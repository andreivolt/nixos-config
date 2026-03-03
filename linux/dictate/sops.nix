{ config, ... }:
let
  p = config.sops.placeholder;
in {
  sops.templates."dictate.env" = {
    owner = "andrei";
    content = "DEEPGRAM_API_KEY=${p."deepgram/api_key"}";
  };
}
