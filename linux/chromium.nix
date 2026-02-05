{pkgs, config, lib, ...}:
let
  inherit (pkgs.stdenv) isLinux;
  isAsahi = pkgs.stdenv.hostPlatform.isAarch64 && isLinux;
in {
  options.chromium.baseFlags = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Base Chromium flags shared across all profiles (main and blank).";
  };

  config = {
    chromium.baseFlags =
      lib.optionals isLinux [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
      ] ++ lib.optionals isAsahi [
        "--font-render-hinting=none"
        "--force-font-family-sans-serif=\"DejaVu Sans Condensed\""
      ];

    # Google API keys for Chromium sign-in/sync
    environment.sessionVariables = lib.mkIf isLinux {
      GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
      GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
    };

    home-manager.users.andrei = {
      programs.chromium = {
        enable = isLinux;
        commandLineArgs = config.chromium.baseFlags;
      };
    };
  };
}
