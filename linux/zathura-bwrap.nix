# Sandboxed zathura — read-only fs, tmpfs home, only bind the opened file
{ pkgs, ... }:
let
  bwrap = "${pkgs.bubblewrap}/bin/bwrap";
  zathura = "${pkgs.zathura}/bin/zathura";
  wrapper = pkgs.writeShellScript "zathura-bwrap" ''
    arg="''${1#file://}"
    file="$(realpath "$arg" 2>/dev/null || echo "$arg")"
    dir="$(dirname "$file")"
    exec ${bwrap} \
      --ro-bind / / \
      --dev /dev \
      --proc /proc \
      --tmpfs /tmp \
      --tmpfs /home/andrei \
      --ro-bind "$dir" "$dir" \
      --bind "$XDG_RUNTIME_DIR" "$XDG_RUNTIME_DIR" \
      --unshare-ipc \
      --die-with-parent \
      --new-session \
      -- ${zathura} "$@"
  '';
in {
  xdg.desktopEntries.zathura = {
    name = "Zathura";
    comment = "A minimalistic document viewer";
    exec = "${wrapper} %f";
    icon = "org.pwmt.zathura";
    terminal = false;
    categories = ["Office" "Viewer"];
    mimeType = ["application/pdf" "application/epub+zip" "application/oxps" "application/x-fictionbook"];
  };
}
