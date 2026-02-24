{
  config,
  lib,
  pkgs,
  ...
}: let
  isDarwin = pkgs.stdenv.isDarwin;
  browser = if isDarwin then "chrome" else "chromium+gnomekeyring";

  mkMpvScript = name: src: pkgs.runCommand name {} ''
    mkdir -p $out/share/mpv/scripts
    cp ${src} $out/share/mpv/scripts/${name}
  '' // { scriptName = name; };

  # patched youtube-chat that skips live streams
  youtube-chat-patched = pkgs.mpvScripts.youtube-chat.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      ./youtube-chat-skip-live.patch
    ];
  });

  sponsorblock-minimal-patched = pkgs.mpvScripts.sponsorblock-minimal.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      ./sponsorblock-minimal-no-osd.patch
      ./sponsorblock-minimal-no-keybind.patch
    ];
  });
  mpv-current = pkgs.writeShellScriptBin "mpv-current" ''
    echo '{ "command": ["get_property", "path"] }' | ${pkgs.socat}/bin/socat - /tmp/mpvsocket | ${pkgs.jq}/bin/jq -r .data
  '';
  mpv-next = pkgs.writeShellScriptBin "mpv-next" ''
    echo '{ "command": ["playlist-next"] }' | ${pkgs.socat}/bin/socat - /tmp/mpvsocket &>/dev/null
  '';
  mpv-prev = pkgs.writeShellScriptBin "mpv-prev" ''
    echo '{ "command": ["playlist-prev"] }' | ${pkgs.socat}/bin/socat - /tmp/mpvsocket &>/dev/null
  '';
in {
  environment.systemPackages = lib.optionals isDarwin [ mpv-current mpv-next mpv-prev ];

  home-manager.sharedModules = [
    {
      programs.mpv = {
        enable = true;

        # home-manager merges lists, so additional scripts in platform-specific
        # modules will be added to this list
        scripts = (with pkgs.mpvScripts; [
          uosc
          thumbfast
          quality-menu
          sponsorblock-minimal-patched
          autosubsync-mpv
          eisa01.undoredo
        ]) ++ [
          youtube-chat-patched
          (mkMpvScript "seek-to.lua" ./seek-to.lua)
          (mkMpvScript "fastforward.lua" ./fastforward.lua)
          (mkMpvScript "auto-save-state.lua" ./auto-save-state.lua)
          (mkMpvScript "ytsub.lua" ./ytsub.lua)
          (mkMpvScript "loading-spinner.lua" ./loading-spinner.lua)
          (mkMpvScript "open-in-browser.lua" ./open-in-browser.lua)
          (mkMpvScript "min-font-size.lua" ./min-font-size.lua)
        ] ++ lib.optionals pkgs.stdenv.isLinux (with pkgs.mpvScripts; [
          mpris
        ]);

        scriptOpts = {
          # removed visibility conditions from subtitles and speed controls
          uosc.controls = "menu,gap,subtitles,<has_many_audio>audio,<has_many_video>video,<has_many_edition>editions,<stream>stream-quality,gap,space,speed,space,shuffle,loop-playlist,loop-file,gap,prev,items,next,gap,fullscreen";
          thumbfast = {
            spawn_first = "yes";
            network = "yes";
            hwdec = "yes";
          };
          "mpv-youtube-chat" = {
            auto-load = "yes";
            anchor = 9;
            message-duration = 20000;
          };
        };

        config = {
          # platform-specific hardware acceleration
          hwdec = if isDarwin then "videotoolbox" else "auto-safe";
          vo = "gpu";
          gpu-api = "vulkan";
          scale = "bilinear";
          dscale = "mitchell";
          cscale = "bilinear";
          keepaspect = "yes";
          keepaspect-window = "yes";
          video-aspect-method = "container";
          ontop = "";
          border = "no";
          geometry = "-40+50%";
          autofit = "30%x30%";
          force-window = "immediate";
          osc = "no";
          term-osd-bar = "yes";
          audio-display = "no";
          input-ipc-server = "/tmp/mpvsocket";
          watch-later-directory = "~/.local/state/mpv/watch_later";
          http-proxy = "http://127.0.0.1:1091";
          sid = "no";
          sub-font-size = 45;
          sub-border-size = 2;
          sub-shadow-offset = 2;
          volume-max = 100;
          msg-level = "all=warn,ffmpeg=fatal";
        };

        bindings = let
          mod = if isDarwin then "Meta" else "Ctrl";
        in {
          "${mod}+c" = "script-binding uosc/copy-to-clipboard";
          "${mod}+z" = "script-binding SimpleUndo/undo";
          "${mod}+Shift+z" = "script-binding SimpleUndo/redo";
          "${mod}+y" = "script-binding SimpleUndo/redo";
          "n" = "script-binding autosubsync/autosubsync-menu";
          "t" = "script-binding seek_to/toggle-seeker";
          "${mod}+j" = "script-message load-chat";
          "${mod}+Shift+j" = "script-message unload-chat";
          "${mod}+Alt+j" = "script-message chat-hidden";
          "${mod}+b" = "script-binding open_in_browser/open-in-browser";
        };
      };

      xdg.configFile."yt-dlp/config".text = ''
        --cookies-from-browser ${browser}
        --remote-components ejs:github
        --format bestvideo[vcodec^=avc]+bestaudio/best
        --proxy http://127.0.0.1:1091
      '';

    }
  ];
}
