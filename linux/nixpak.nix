# Declarative application sandboxing via nixpak (bubblewrap)
{ pkgs, lib, config, inputs, ... }:
let
  mkNixPak = inputs.nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  isx86 = pkgs.stdenv.hostPlatform.isx86_64;
  isAarch64 = pkgs.stdenv.hostPlatform.isAarch64;

  # Common ro-binds for all GUI sandboxes:
  # - /run/current-system: cursor themes, system binaries (hyprctl etc.)
  # - Apple Silicon GPU: platform devices (nixpak's gpu module only binds PCI paths)
  commonRoBinds = [
    "/run/current-system"
  ] ++ lib.optionals isAarch64 [
    "/sys/devices/platform"
    "/sys/class/drm"
  ];

  # Fonts, dark mode, locale — sloth-dependent, call with each sandbox's sloth
  guiRoBinds = sloth: [
    "/etc/fonts"
    "/etc/localtime"
    (sloth.concat' sloth.homeDir "/.config/gtk-3.0")
    (sloth.concat' sloth.homeDir "/.config/gtk-4.0")
    (sloth.concat' sloth.homeDir "/.config/dconf")
  ];

  commonDbusPolices = {
    "org.freedesktop.Notifications" = "talk";
    "org.freedesktop.portal.Desktop" = "talk";
    "org.freedesktop.portal.Settings" = "talk";
  };

  # Access HM mpv scripts to build identical mpv-with-scripts for sandboxing
  hmMpvScripts = config.home-manager.users.andrei.programs.mpv.scripts;
  mpvWithScripts = pkgs.mpv.override {
    scripts = hmMpvScripts;
  };

  # -- Sandboxed app definitions --

  mpvSandboxed = mkNixPak {
    config = { sloth, ... }: {
      app.package = mpvWithScripts;
      bubblewrap = {
        network = true;
        bind.ro = [
          (sloth.concat' sloth.homeDir "/.config/mpv")
          (sloth.env "MEDIA_DIR")
        ] ++ guiRoBinds sloth ++ commonRoBinds;
        bind.rw = [
          (sloth.concat' sloth.homeDir "/.local/state/mpv")
          (sloth.env "XDG_RUNTIME_DIR")
        ];
        tmpfs = [ "/tmp" ];
        bind.dev = [ "/dev/dri" ];
      };
      gpu.enable = true;
    };
  };

  mpvWrapper = pkgs.writeShellScript "mpv-sandboxed" ''
    mkdir -p ~/.local/state/mpv
    export MEDIA_DIR="/tmp"
    for arg in "$@"; do
      case "$arg" in
        -*) ;;
        *)
          arg="''${arg#file://}"
          real="$(realpath "$arg" 2>/dev/null || echo "$arg")"
          export MEDIA_DIR="$(dirname "$real")"
          break
          ;;
      esac
    done
    exec ${mpvSandboxed.config.env}/bin/mpv "$@"
  '';

  telegramSandboxed = mkNixPak {
    config = { sloth, ... }: {
      app.package = pkgs.telegram-desktop;
      bubblewrap = {
        network = true;
        sockets.wayland = true;
        sockets.pipewire = true;
        bind.rw = [
          (sloth.concat' sloth.homeDir "/.local/share/TelegramDesktop")
          (sloth.concat' sloth.homeDir "/Downloads")
        ];
        bind.ro = guiRoBinds sloth ++ commonRoBinds;
        bind.dev = [ "/dev/dri" ];
      };
      gpu.enable = true;
      dbus.enable = true;
      dbus.policies = commonDbusPolices;
    };
  };

  zathuraSandboxed = mkNixPak {
    config = { sloth, ... }: {
      app.package = pkgs.zathura;
      bubblewrap = {
        network = false;
        sockets.wayland = true;
        bind.ro = [
          (sloth.env "DOCUMENT_DIR")
        ] ++ guiRoBinds sloth ++ commonRoBinds;
        bind.dev = [ "/dev/dri" ];
      };
      gpu.enable = true;
      dbus.enable = true;
      dbus.policies = commonDbusPolices;
    };
  };

  zathuraWrapper = pkgs.writeShellScript "zathura-sandboxed" ''
    arg="''${1#file://}"
    file="$(realpath "$arg" 2>/dev/null || echo "$arg")"
    export DOCUMENT_DIR="$(dirname "$file")"
    exec ${zathuraSandboxed.config.env}/bin/zathura "$@"
  '';

  chromiumTorArgs = config.chromium.baseArgs ++ [
    "--proxy-server=socks5://127.0.0.1:9050"
    "--no-first-run"
    "--no-default-browser-check"
  ];

  chromiumTorInner = pkgs.writeShellScriptBin "chromium-tor" ''
    datadir="$XDG_RUNTIME_DIR/chromium-tor"
    mkdir -p "$datadir"
    exec ${pkgs.chromium}/bin/chromium \
      ${lib.escapeShellArgs chromiumTorArgs} \
      "--user-data-dir=$datadir" "$@"
  '';

  chromiumTorSandboxed = mkNixPak {
    config = { sloth, ... }: {
      app.package = chromiumTorInner;
      app.binPath = "bin/chromium-tor";
      bubblewrap = {
        network = true;
        sockets.wayland = true;
        sockets.pipewire = true;
        bind.rw = [
          (sloth.concat' (sloth.env "XDG_RUNTIME_DIR") "/chromium-tor")
          "/dev/shm"
        ];
        bind.ro = guiRoBinds sloth ++ commonRoBinds;
        bind.dev = [ "/dev/dri" ];
        tmpfs = [ "/tmp" ];
      };
      gpu.enable = true;
      dbus.enable = true;
      dbus.policies = commonDbusPolices;
    };
  };

  chromiumTorWrapper = pkgs.writeShellScript "chromium-tor-sandboxed" ''
    mkdir -p "$XDG_RUNTIME_DIR/chromium-tor"
    exec ${chromiumTorSandboxed.config.env}/bin/chromium-tor "$@"
  '';

  swayimgSandboxed = mkNixPak {
    config = { sloth, ... }: {
      app.package = pkgs.swayimg;
      bubblewrap = {
        network = false;
        sockets.wayland = true;
        bind.ro = [
          (sloth.env "IMAGE_DIR")
          (sloth.concat' sloth.homeDir "/.config/swayimg")
        ] ++ guiRoBinds sloth ++ commonRoBinds;
        bind.dev = [ "/dev/dri" ];
      };
      gpu.enable = true;
    };
  };

  swayimgWrapper = pkgs.writeShellScript "swayimg-sandboxed" ''
    arg="''${1#file://}"
    file="$(realpath "$arg" 2>/dev/null || echo "$arg")"
    export IMAGE_DIR="$(dirname "$file")"
    exec ${swayimgSandboxed.config.env}/bin/swayimg "$@"
  '';

  # x86-only apps
  discordSandboxed = lib.optionalAttrs isx86 (mkNixPak {
    config = { sloth, ... }: {
      app.package = pkgs.discord;
      bubblewrap = {
        network = true;
        sockets.wayland = true;
        sockets.pipewire = true;
        bind.rw = [
          (sloth.concat' sloth.homeDir "/.config/discord")
          (sloth.concat' sloth.homeDir "/Downloads")
        ];
        bind.ro = guiRoBinds sloth ++ commonRoBinds;
        bind.dev = [ "/dev/dri" ];
      };
      gpu.enable = true;
      dbus.enable = true;
      dbus.policies = commonDbusPolices;
    };
  });

  slackSandboxed = lib.optionalAttrs isx86 (mkNixPak {
    config = { sloth, ... }: {
      app.package = pkgs.slack;
      bubblewrap = {
        network = true;
        sockets.wayland = true;
        sockets.pipewire = true;
        bind.rw = [
          (sloth.concat' sloth.homeDir "/.config/Slack")
          (sloth.concat' sloth.homeDir "/Downloads")
        ];
        bind.ro = guiRoBinds sloth ++ commonRoBinds;
        bind.dev = [ "/dev/dri" ];
      };
      gpu.enable = true;
      dbus.enable = true;
      dbus.policies = commonDbusPolices;
    };
  });

  spotifySandboxed = lib.optionalAttrs isx86 (mkNixPak {
    config = { sloth, ... }: {
      app.package = pkgs.spotify;
      bubblewrap = {
        network = true;
        sockets.wayland = true;
        sockets.pipewire = true;
        bind.rw = [
          (sloth.concat' sloth.homeDir "/.config/spotify")
          (sloth.concat' sloth.homeDir "/.cache/spotify")
        ];
        bind.ro = guiRoBinds sloth ++ commonRoBinds;
        bind.dev = [ "/dev/dri" ];
      };
      gpu.enable = true;
      dbus.enable = true;
      dbus.policies = commonDbusPolices // {
        "org.mpris.MediaPlayer2.spotify" = "own";
      };
    };
  });

in {
  home-manager.users.andrei = {
    xdg.desktopEntries.mpv = {
      name = "mpv Media Player";
      genericName = "Multimedia player";
      exec = "${mpvWrapper} -- %f";
      icon = "mpv";
      terminal = false;
      categories = ["AudioVideo" "Audio" "Video" "Player"];
      mimeType = [
        "video/mp4" "video/x-matroska" "video/webm" "video/avi"
        "audio/mpeg" "audio/flac" "audio/ogg" "audio/opus"
      ];
    };

    xdg.desktopEntries.telegram = {
      name = "Telegram";
      genericName = "Messaging";
      exec = "${telegramSandboxed.config.env}/bin/Telegram %u";
      icon = "telegram";
      terminal = false;
      categories = ["Network" "InstantMessaging"];
    };

    xdg.desktopEntries.zathura = {
      name = "Zathura";
      comment = "A minimalistic document viewer";
      exec = "${zathuraWrapper} %f";
      icon = "org.pwmt.zathura";
      terminal = false;
      categories = ["Office" "Viewer"];
      mimeType = ["application/pdf" "application/epub+zip" "application/oxps" "application/x-fictionbook"];
    };

    xdg.desktopEntries.chromium-tor = {
      name = "Chromium (Tor)";
      genericName = "Web Browser";
      exec = "${chromiumTorWrapper} %U";
      icon = "chromium";
      terminal = false;
      categories = ["Network" "WebBrowser"];
      actions = {
        "new-window" = {
          name = "New Window";
          exec = "${chromiumTorWrapper}";
        };
        "new-private-window" = {
          name = "New Incognito Window";
          exec = "${chromiumTorWrapper} --incognito";
        };
      };
    };

    xdg.desktopEntries.swayimg = {
      name = "Swayimg";
      comment = "Image viewer for Wayland";
      exec = "${swayimgWrapper} %f";
      icon = "swayimg";
      terminal = false;
      categories = ["Graphics" "Viewer"];
      mimeType = ["image/jpeg" "image/png" "image/gif" "image/bmp" "image/webp" "image/avif" "image/heic" "image/heif" "image/tiff" "image/svg+xml"];
    };
  } // lib.optionalAttrs isx86 {
    xdg.desktopEntries.discord = {
      name = "Discord";
      exec = "${discordSandboxed.config.env}/bin/Discord %U";
      icon = "discord";
      terminal = false;
      categories = ["Network" "InstantMessaging"];
    };

    xdg.desktopEntries.slack = {
      name = "Slack";
      exec = "${slackSandboxed.config.env}/bin/slack %U";
      icon = "slack";
      terminal = false;
      categories = ["Network" "InstantMessaging"];
    };

    xdg.desktopEntries.spotify = {
      name = "Spotify";
      exec = "${spotifySandboxed.config.env}/bin/spotify %U";
      icon = "spotify";
      terminal = false;
      categories = ["Audio" "Music" "Player"];
    };
  };
}
