# Sandboxed Telegram — read-only fs, tmpfs home, bind only Telegram data
{ pkgs, ... }:
let
  bwrap = "${pkgs.bubblewrap}/bin/bwrap";
  telegram = "${pkgs.telegram-desktop}/bin/Telegram";
  dataDir = "/home/andrei/.local/share/TelegramDesktop";
  downloadDir = "/home/andrei/Downloads";
  wrapper = pkgs.writeShellScript "telegram-bwrap" ''
    mkdir -p ${dataDir} ${downloadDir}
    exec ${bwrap} \
      --ro-bind / / \
      --dev /dev \
      --proc /proc \
      --tmpfs /tmp \
      --tmpfs /home/andrei \
      --bind ${dataDir} ${dataDir} \
      --bind ${downloadDir} ${downloadDir} \
      --bind "$XDG_RUNTIME_DIR" "$XDG_RUNTIME_DIR" \
      --unshare-ipc \
      --die-with-parent \
      --new-session \
      -- ${telegram} "$@"
  '';
in {
  home-manager.users.andrei.xdg.desktopEntries.telegram = {
    name = "Telegram";
    genericName = "Messaging";
    exec = "${wrapper} -- %u";
    icon = "telegram";
    terminal = false;
    categories = ["Network" "InstantMessaging"];
  };
}
