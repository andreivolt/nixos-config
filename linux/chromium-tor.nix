# Chromium Tor profile — routes all traffic through Tor SOCKS5, no extensions
# Sandboxed with bwrap: home is tmpfs, filesystem is read-only
{ pkgs, config, lib, ... }:
let
  chromium = "${pkgs.chromium}/bin/chromium";
  bwrap = "${pkgs.bubblewrap}/bin/bwrap";
  args = config.chromium.baseArgs ++ [
    "--proxy-server=socks5://127.0.0.1:9050"
    "--no-first-run"
    "--no-default-browser-check"
  ];
  wrapper = pkgs.writeShellScript "chromium-tor" ''
    datadir="$XDG_RUNTIME_DIR/chromium-tor"
    mkdir -p "$datadir"
    exec ${bwrap} \
      --ro-bind / / \
      --dev /dev \
      --proc /proc \
      --tmpfs /tmp \
      --tmpfs /home/andrei \
      --bind "$datadir" "$datadir" \
      --bind "$XDG_RUNTIME_DIR" "$XDG_RUNTIME_DIR" \
      --unshare-ipc \
      --die-with-parent \
      --new-session \
      -- ${chromium} ${lib.escapeShellArgs args} "--user-data-dir=$datadir" "$@"
  '';
in {
  home-manager.users.andrei.xdg.desktopEntries.chromium-tor = {
    name = "Chromium (Tor)";
    genericName = "Web Browser";
    exec = "${wrapper} %U";
    icon = "chromium";
    terminal = false;
    categories = ["Network" "WebBrowser"];
    actions = {
      "new-window" = {
        name = "New Window";
        exec = "${wrapper}";
      };
      "new-private-window" = {
        name = "New Incognito Window";
        exec = "${wrapper} --incognito";
      };
    };
  };
}
