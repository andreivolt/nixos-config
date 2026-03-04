# yt-dlp HTTP API - runs yt-dlp behind an HTTP server on the tailnet
# Fly.io youtube-transcripts app calls this over Tailscale instead of using a proxy
{ config, ... }: {
  sops.templates."yt-dlp-api-ts.env" = {
    content = ''
      TS_AUTHKEY=${config.sops.placeholder."headscale/authkey"}
    '';
  };

  services.yt-dlp-api = {
    enable = true;
    tsAuthKeyFile = config.sops.templates."yt-dlp-api-ts.env".path;
  };
}
