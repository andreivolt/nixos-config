{ pkgs, config, inputs, ... }:
let
  np = import ./lib.nix { inherit pkgs inputs; inherit (pkgs) lib; };
  inherit (np) mkNixPak guiRoBinds commonRoBinds;

  hmMpvScripts = config.home-manager.users.andrei.programs.mpv.scripts;
  mpvWithScripts = pkgs.mpv.override { scripts = hmMpvScripts; };

  sandboxed = mkNixPak {
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

  wrapper = pkgs.writeShellScript "mpv-sandboxed" ''
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
    exec ${sandboxed.config.env}/bin/mpv "$@"
  '';
in {
  home-manager.users.andrei.xdg.desktopEntries.mpv = {
    name = "mpv Media Player";
    genericName = "Multimedia player";
    exec = "${wrapper} -- %f";
    icon = "mpv";
    terminal = false;
    categories = ["AudioVideo" "Audio" "Video" "Player"];
    mimeType = [
      "video/mp4" "video/x-matroska" "video/webm" "video/avi"
      "audio/mpeg" "audio/flac" "audio/ogg" "audio/opus"
    ];
  };
}
