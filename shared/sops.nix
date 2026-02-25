{ config, lib, pkgs, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
  user = "andrei";

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
    "elevenlabs/avoltnet_api_key"
    "exa/api_key"
    "filebase/access_key"
    "filebase/endpoint_url"
    "filebase/region"
    "filebase/secret_access_key"
    "filebase/token"
    "fal/api_key"
    "firecrawl/api_key"
    "gdrive/client_id"
    "gdrive/client_secret"
    "gemini/api_key"
    "giphy/api_key"
    "github/token"
    "google/client_id"
    "google/client_secret"
    "lastfm/api_key"
    "lastfm/api_secret"
    "lastfm/username"
    "livekit/api_key"
    "livekit/api_secret"
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
    "puremd/api_key"
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
    "tailscale/login_server"
    "tailscale/net"
    "tailscale/org"
    "telegram/api_hash"
    "tidal/client_id"
    "tidal/client_secret"
    "telegram/api_id"
    "unrealspeech/api_key"
    "vocode/api_key"
    "webshare/proxy_password"
    "webshare/proxy_username"
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
      oci_api_key_pem = { owner = user; };
    };

    templates = {
      "session-env" = {
        owner = user;
        content = ''
          GITHUB_TOKEN=${p."github/token"}
          NIX_CONFIG=access-tokens = github.com=${p."github/token"}
          OPENROUTER_KEY=${p."openrouter/api_key"}
        '';
      };

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
    };
  };
}
