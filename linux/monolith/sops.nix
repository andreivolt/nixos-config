{ config, lib, pkgs, ... }:
let
  user = "andrei";
  p = config.sops.placeholder;

  mkEnvFile = vars: lib.concatStringsSep "\n"
    (lib.mapAttrsToList (name: placeholder: "${name}=${placeholder}") vars);
in {
  sops.secrets = {
    "monolith/gcloud_vision_sa_json" = { owner = user; };
    "monolith/github_client_id" = { owner = user; };
    "monolith/github_client_secret" = { owner = user; };
    "monolith/google_api_key" = { owner = user; };
    "monolith/google_client_id" = { owner = user; };
    "monolith/google_client_secret" = { owner = user; };
  };

  sops.templates = {
    "monolith.env" = {
      owner = user;
      content = mkEnvFile {
        AZURE_SPEECH_KEY = p."azure_speech/key";
        AZURE_SPEECH_REGION = p."azure_speech/region";
        CARTESIA_API_KEY = p."cartesia/api_key";
        DEEPGRAM_API_KEY = p."deepgram/api_key";
        ELEVENLABS_API_KEY = p."elevenlabs/avoltnet_api_key";
        EXA_API_KEY = p."exa/api_key";
        FAL_KEY = p."fal/api_key";
        FILEBASE_ACCESS_KEY = p."filebase/access_key";
        FILEBASE_SECRET_KEY = p."filebase/secret_access_key";
        FILEBASE_TOKEN = p."filebase/token";
        FIRECRAWL_API_KEY = p."firecrawl/api_key";
        GEMINI_API_KEY = p."gemini/api_key";
        GIPHY_API_KEY = p."giphy/api_key";
        GITHUB_CLIENT_ID = p."monolith/github_client_id";
        GITHUB_CLIENT_SECRET = p."monolith/github_client_secret";
        GOOGLE_API_KEY = p."monolith/google_api_key";
        GOOGLE_APPLICATION_CREDENTIALS = config.sops.templates."gcloud-vision-sa".path;
        GOOGLE_CLIENT_ID = p."monolith/google_client_id";
        GOOGLE_CLIENT_SECRET = p."monolith/google_client_secret";
        LASTFM_API_KEY = p."lastfm/api_key";
        LASTFM_USERNAME = p."lastfm/username";
        LIFX_TOKEN = p."lifx/token";
        OPENAI_API_KEY = p."openai/api_key";
        OPENROUTER_KEY = p."openrouter/api_key";
        PERPLEXITY_API_KEY = p."perplexity/api_key";
        PIRATEWEATHER_API_KEY = p."pirateweather/api_key";
        PUREMD_API_KEY = p."puremd/api_key";
        PUSHOVER_TOKEN = p."pushover/token";
        PUSHOVER_USER = p."pushover/user";
        REDDIT_CLIENT_ID = p."reddit/client_id";
        REDDIT_CLIENT_SECRET = p."reddit/client_secret";
        REDDIT_PASSWORD = p."reddit/password";
        REDDIT_USERNAME = p."reddit/username";
        REPLICATE_API_TOKEN = p."replicate/api_token";
        SERPAPI_API_KEY = p."serpapi/api_key";
        SPOTIFY_CLIENT_ID = p."spotify/client_id";
        SPOTIFY_CLIENT_SECRET = p."spotify/client_secret";
        TAILSCALE_API_KEY = p."tailscale/api_key";
        TAILSCALE_LOGIN_SERVER = p."tailscale/login_server";
        TELEGRAM_API_HASH = p."telegram/api_hash";
        TELEGRAM_API_ID = p."telegram/api_id";
        UNREALSPEECH_API_KEY = p."unrealspeech/api_key";
        WEBSHARE_PROXY_PASSWORD = p."webshare/proxy_password";
        WEBSHARE_PROXY_USERNAME = p."webshare/proxy_username";
        XAI_API_KEY = p."xai/api_key";
      };
    };

    "gcloud-vision-sa" = {
      owner = user;
      content = p."monolith/gcloud_vision_sa_json";
    };
  };
}
