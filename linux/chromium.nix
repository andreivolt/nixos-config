{pkgs, config, lib, ...}:
let
  # Only enable full Chromium config on aarch64-linux (Asahi/ARM)
  # where google-chrome is not available
  isAsahi = pkgs.stdenv.hostPlatform.isAarch64 && pkgs.stdenv.isLinux;
in {
  options.chromium.baseFlags = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Base Chromium flags shared across all profiles (main and blank).";
  };

  config = {
    chromium.baseFlags = lib.mkIf isAsahi [
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"
      "--font-render-hinting=none"
      "--force-font-family-sans-serif=\"DejaVu Sans Condensed\""
    ];

    # Google API keys for Chromium sign-in/sync - only on Asahi
    # These env vars can interfere with google-chrome's built-in keys
    environment.sessionVariables = lib.mkIf isAsahi {
      GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
      GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
    };

    home-manager.users.andrei = {
      programs.chromium = {
        enable = isAsahi;
        commandLineArgs = config.chromium.baseFlags;
      };
    };
  };
}
