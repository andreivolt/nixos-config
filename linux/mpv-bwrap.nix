# Sandboxed mpv — read-only fs, tmpfs home, bind media file + state
{ pkgs, ... }:
let
  bwrap = "${pkgs.bubblewrap}/bin/bwrap";
  stateDir = "/home/andrei/.local/state/mpv";
  wrapper = pkgs.writeShellScript "mpv-bwrap" ''
    mkdir -p ${stateDir}
    # Use HM-wrapped mpv (includes scripts like uosc) resolved before sandbox
    mpv_bin="$(readlink -f /home/andrei/.nix-profile/bin/mpv)"
    # Resolve first non-flag arg as the media file
    file_bind=()
    for arg in "$@"; do
      case "$arg" in
        -*) ;;
        *)
          real="$(realpath "$arg" 2>/dev/null || echo "$arg")"
          dir="$(dirname "$real")"
          file_bind=(--ro-bind "$dir" "$dir")
          break
          ;;
      esac
    done
    exec ${bwrap} \
      --ro-bind / / \
      --dev /dev \
      --dev-bind /dev/dri /dev/dri \
      --proc /proc \
      --tmpfs /tmp \
      --tmpfs /home/andrei \
      --ro-bind /home/andrei/.config/mpv /home/andrei/.config/mpv \
      --bind ${stateDir} ${stateDir} \
      --bind "$XDG_RUNTIME_DIR" "$XDG_RUNTIME_DIR" \
      "''${file_bind[@]}" \
      --unshare-ipc \
      --die-with-parent \
      --new-session \
      -- "$mpv_bin" "$@"
  '';
in {
  home-manager.users.andrei.xdg.desktopEntries.mpv = {
    name = "mpv Media Player";
    genericName = "Multimedia player";
    exec = "${wrapper} -- %U";
    icon = "mpv";
    terminal = false;
    categories = ["AudioVideo" "Audio" "Video" "Player"];
    mimeType = [
      "video/mp4" "video/x-matroska" "video/webm" "video/avi"
      "audio/mpeg" "audio/flac" "audio/ogg" "audio/opus"
    ];
  };
}
