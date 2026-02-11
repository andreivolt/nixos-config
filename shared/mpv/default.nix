{
  config,
  lib,
  pkgs,
  ...
}: let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  isAsahi = isLinux && pkgs.stdenv.hostPlatform.isAarch64;
  browser = if isAsahi then "chromium+gnomekeyring" else "chrome";

  # custom seek-to with paste-timestamp functionality
  seek-to-custom = pkgs.runCommand "seek-to-custom" {} ''
    mkdir -p $out/share/mpv/scripts
    cp ${./seek-to.lua} $out/share/mpv/scripts/seek-to.lua
  '' // { scriptName = "seek-to.lua"; };

  # patched youtube-chat that skips live streams
  youtube-chat-patched = pkgs.mpvScripts.youtube-chat.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      ./youtube-chat-skip-live.patch
    ];
  });

  customScriptsDir = pkgs.runCommand "mpv-custom-scripts" {} ''
    mkdir -p $out
    cp ${./fastforward.lua} $out/fastforward.lua
    cp ${./auto-save-state.lua} $out/auto-save-state.lua
    cp ${./ytsub.lua} $out/ytsub.lua
  '';
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
          sponsorblock-minimal
          autosubsync-mpv
          eisa01.undoredo
        ]) ++ [
          youtube-chat-patched
          seek-to-custom
        ] ++ lib.optionals isLinux (with pkgs.mpvScripts; [
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
          ytdl-format = "bestvideo[vcodec^=avc]+bestaudio/best";
          ytdl-raw-options = "cookies-from-browser=${browser}";
          sub-font-size = 45;
          sub-border-size = 2;
          sub-shadow-offset = 2;
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
        };
      };

      xdg.configFile."yt-dlp/config".text = ''
        --cookies-from-browser ${browser}
        --remote-components ejs:github
      '';

      # custom scripts not in nixpkgs
      xdg.configFile = {
        "mpv/scripts/fastforward.lua".source = "${customScriptsDir}/fastforward.lua";
        "mpv/scripts/auto-save-state.lua".source = "${customScriptsDir}/auto-save-state.lua";
        "mpv/scripts/ytsub.lua".source = "${customScriptsDir}/ytsub.lua";
      };
    }
  ];
}
