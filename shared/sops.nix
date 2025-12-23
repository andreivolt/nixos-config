{ config, lib, pkgs, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
  user = "andrei";

  mkEnvFile = vars: lib.concatStringsSep "\n"
    (lib.mapAttrsToList (name: placeholder: "${name}=${placeholder}") vars);

  secretPaths = [
    "amo/api_key"
    "amo/api_secret"
    "anthropic/api_key"
    "aws/access_key_id"
    "aws/region"
    "aws/secret_access_key"
    "azure_speech/key"
    "azure_speech/region"
    "backblaze/access_key"
    "backblaze/bucket"
    "backblaze/endpoint_url"
    "backblaze/region"
    "backblaze/secret_access_key"
    "cartesia/api_key"
    "chrome_web_store/client_id"
    "chrome_web_store/client_secret"
    "coinmarketcap/api_key"
    "deepgram/api_key"
    "dnsimple/access_token"
    "dnsimple/account_id"
    "elevenlabs/api_key"
    "exa/api_key"
    "filebase/access_key"
    "filebase/endpoint_url"
    "filebase/region"
    "filebase/secret_access_key"
    "filebase/token"
    "firecrawl/api_key"
    "gdrive/client_id"
    "gdrive/client_secret"
    "gemini/api_key"
    "github/token"
    "google/client_id"
    "google/client_secret"
    "monolith/gcloud_vision_sa_json"
    "monolith/google_api_key"
    "monolith/google_client_id"
    "monolith/google_client_secret"
    "lastfm/api_key"
    "lastfm/api_secret"
    "lastfm/username"
    "lifx/token"
    "linode/token"
    "nextdns/setup_id"
    "nextdns/token"
    "openai/api_key"
    "openai/org_id"
    "openrouter/api_key"
    "perplexity/api_key"
    "pinata/api_key"
    "pinata/api_secret"
    "pinecone/api_key"
    "pirateweather/api_key"
    "playht/secret_key"
    "playht/user_id"
    "poe/token"
    "porcupine/access_key"
    "pushover/token"
    "pushover/user"
    "reddit/client_id"
    "reddit/client_secret"
    "reddit/password"
    "reddit/username"
    "replicate/api_token"
    "rime/api_key"
    "serpapi/api_key"
    "speechmatics/api_key"
    "spotify/client_id"
    "spotify/client_secret"
    "supadata/api_key"
    "tailscale/api_key"
    "tailscale/auth_key"
    "tailscale/login_server"
    "tailscale/net"
    "tailscale/org"
    "telegram/api_hash"
    "telegram/api_id"
    "unrealspeech/api_key"
    "vocode/api_key"
    "xai/api_key"
    "zoom/account_id"
    "zoom/client_id"
    "zoom/client_secret"
  ];

  secretsFromPaths = paths: lib.listToAttrs (map (path: {
    name = path;
    value = { owner = user; };
  }) paths);

  p = config.sops.placeholder;
in {
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    age.sshKeyPaths =
      if isDarwin then [ "/etc/ssh/ssh_host_ed25519_key" ]
      else [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

    secrets = secretsFromPaths secretPaths // {
      email = { owner = user; };
      asciinema_install_id = { owner = user; };
      oci_api_key_pem = { owner = user; };
    };

    templates = {
      "aws-credentials" = {
        owner = user;
        content = lib.generators.toINI {} {
          default = {
            aws_access_key_id = p."aws/access_key_id";
            aws_secret_access_key = p."aws/secret_access_key";
          };
          backblaze = {
            aws_access_key_id = p."backblaze/access_key";
            aws_secret_access_key = p."backblaze/secret_access_key";
          };
          filebase = {
            aws_access_key_id = p."filebase/access_key";
            aws_secret_access_key = p."filebase/secret_access_key";
          };
        };
      };

      "aws-config" = {
        owner = user;
        content = lib.generators.toINI {} {
          default = {
            region = p."aws/region";
          };
          "profile backblaze" = {
            region = p."backblaze/region";
            endpoint_url = p."backblaze/endpoint_url";
          };
          "profile filebase" = {
            region = p."filebase/region";
            endpoint_url = p."filebase/endpoint_url";
          };
        };
      };

      "monolith.env" = {
        owner = user;
        content = mkEnvFile {
          ANTHROPIC_API_KEY = p."anthropic/api_key";
          AZURE_SPEECH_KEY = p."azure_speech/key";
          AZURE_SPEECH_REGION = p."azure_speech/region";
          CARTESIA_API_KEY = p."cartesia/api_key";
          DEEPGRAM_API_KEY = p."deepgram/api_key";
          ELEVENLABS_API_KEY = p."elevenlabs/api_key";
          EXA_API_KEY = p."exa/api_key";
          FILEBASE_ACCESS_KEY = p."filebase/access_key";
          FILEBASE_SECRET_KEY = p."filebase/secret_access_key";
          FILEBASE_TOKEN = p."filebase/token";
          FIRECRAWL_API_KEY = p."firecrawl/api_key";
          GEMINI_API_KEY = p."gemini/api_key";
          GOOGLE_API_KEY = p."monolith/google_api_key";
          GOOGLE_APPLICATION_CREDENTIALS = config.sops.templates."gcloud-vision-sa".path;
          GOOGLE_CLIENT_ID = p."monolith/google_client_id";
          GOOGLE_CLIENT_SECRET = p."monolith/google_client_secret";
          LIFX_TOKEN = p."lifx/token";
          OPENAI_API_KEY = p."openai/api_key";
          OPENROUTER_KEY = p."openrouter/api_key";
          PERPLEXITY_API_KEY = p."perplexity/api_key";
          PUSHOVER_TOKEN = p."pushover/token";
          PUSHOVER_USER = p."pushover/user";
          REDDIT_CLIENT_ID = p."reddit/client_id";
          REDDIT_CLIENT_SECRET = p."reddit/client_secret";
          REDDIT_PASSWORD = p."reddit/password";
          REDDIT_USERNAME = p."reddit/username";
          REPLICATE_API_TOKEN = p."replicate/api_token";
          SERPAPI_API_KEY = p."serpapi/api_key";
          TAILSCALE_API_KEY = p."tailscale/api_key";
          TAILSCALE_AUTH_KEY = p."tailscale/auth_key";
          TAILSCALE_LOGIN_SERVER = p."tailscale/login_server";
          TAILSCALE_ORG = p."tailscale/org";
          TELEGRAM_API_HASH = p."telegram/api_hash";
          TELEGRAM_API_ID = p."telegram/api_id";
          UNREALSPEECH_API_KEY = p."unrealspeech/api_key";
          XAI_API_KEY = p."xai/api_key";
        };
      };

      "linode-cli" = {
        owner = user;
        content = lib.generators.toINI {} {
          DEFAULT = {
            default-user = "andreivolt";
          };
          andreivolt = {
            token = p."linode/token";
            region = "eu-west";
          };
        };
      };

      "gdrive3-secret" = {
        owner = user;
        content = builtins.toJSON {
          client_id = p."gdrive/client_id";
          client_secret = p."gdrive/client_secret";
        };
      };

      "gcloud-vision-sa" = {
        owner = user;
        content = p."monolith/gcloud_vision_sa_json";
      };
    };
  };
}
