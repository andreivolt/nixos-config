{pkgs, ...}: let
  inherit (pkgs.stdenv) isLinux isDarwin;

  chromiumManifest = pkgs.writeText "ff2mpv.json" (builtins.toJSON {
    name = "ff2mpv";
    description = "ff2mpv's external manifest";
    path = "${pkgs.ff2mpv}/bin/ff2mpv.py";
    type = "stdio";
    allowed_origins = ["chrome-extension://ephjcajbkgplkjmelpglennepbpmdpjg/"];
  });
in {
  home-manager.users.andrei = {
    home.file = {
      # Linux paths
      ".config/chromium/NativeMessagingHosts/ff2mpv.json" = {
        enable = isLinux;
        source = chromiumManifest;
      };
      ".config/google-chrome/NativeMessagingHosts/ff2mpv.json" = {
        enable = isLinux;
        source = chromiumManifest;
      };
      # macOS paths
      "Library/Application Support/Google/Chrome/NativeMessagingHosts/ff2mpv.json" = {
        enable = isDarwin;
        source = chromiumManifest;
      };
      "Library/Application Support/Chromium/NativeMessagingHosts/ff2mpv.json" = {
        enable = isDarwin;
        source = chromiumManifest;
      };
    };
  };
}
