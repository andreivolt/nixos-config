{ pkgs, lib, config, inputs, ... }:
let
  np = import ./lib.nix { inherit pkgs inputs; inherit (pkgs) lib; };
  inherit (np) mkNixPak guiRoBinds commonRoBinds commonDbusPolices;

  hmMpvScripts = config.home-manager.users.andrei.programs.mpv.scripts;
  mpvWithScripts = pkgs.mpv.override { scripts = hmMpvScripts; };

  sandboxed = mkNixPak {
    config = { sloth, ... }: {
      app.package = mpvWithScripts;
      bubblewrap = {
        network = true;
        bind.ro = [
          (sloth.concat' sloth.homeDir "/.config/mpv")
          # yt-dlp needs its config, chromium cookie db, and gnome-keyring D-Bus access for YouTube auth
          (sloth.concat' sloth.homeDir "/.config/yt-dlp")
          (sloth.concat' sloth.homeDir "/.config/chromium/Local State")
          (sloth.concat' sloth.homeDir "/.config/chromium/Default/Cookies")
          (sloth.env "MEDIA_DIR")
        ] ++ guiRoBinds sloth ++ commonRoBinds;
        bind.rw = [
          (sloth.concat' sloth.homeDir "/.local/state/mpv")
          (sloth.env "XDG_RUNTIME_DIR")
        ];
        tmpfs = [ "/tmp" ];
        bind.dev = [ "/dev/dri" ];
      };
      dbus.enable = true;
      dbus.policies = commonDbusPolices // {
        "org.freedesktop.secrets" = "talk";
      };
      gpu.enable = true;
    };
  };

  wrapperBin = pkgs.writeShellScriptBin "mpv" ''
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

  wrapper = pkgs.symlinkJoin {
    name = "mpv-sandboxed";
    paths = [ wrapperBin ];
    postBuild = ''
      mkdir -p $out/share
      for dir in zsh bash-completion fish man; do
        [ -d ${pkgs.mpv}/share/$dir ] && ln -s ${pkgs.mpv}/share/$dir $out/share/$dir
      done
    '';
  };
in {
  home-manager.users.andrei.home.packages = [ (lib.hiPrio wrapper) ];
  home-manager.users.andrei.xdg.desktopEntries.mpv = {
    name = "mpv Media Player";
    genericName = "Multimedia player";
    exec = "${wrapperBin}/bin/mpv -- %f";
    icon = "mpv";
    terminal = false;
    categories = ["AudioVideo" "Audio" "Video" "Player"];
    mimeType = [
      "video/mp4" "video/x-matroska" "video/webm" "video/avi"
      "audio/mpeg" "audio/flac" "audio/ogg" "audio/opus"
    ];
  };
}
