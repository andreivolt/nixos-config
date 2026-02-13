{
  writeShellScriptBin,
  systemd,
  coreutils,
}:
writeShellScriptBin "lan-mouse-toggle" ''
  STATE_FILE="''${HOME}/.local/state/lan-mouse-disabled"

  is_active() {
    ${systemd}/bin/systemctl --user is-active --quiet lan-mouse
  }

  enable() {
    ${coreutils}/bin/rm -f "$STATE_FILE"
    ${systemd}/bin/systemctl --user start lan-mouse
  }

  disable() {
    ${coreutils}/bin/mkdir -p "$(${coreutils}/bin/dirname "$STATE_FILE")"
    ${coreutils}/bin/touch "$STATE_FILE"
    ${systemd}/bin/systemctl --user stop lan-mouse
  }

  case "''${1:-toggle}" in
    on)      enable ;;
    off)     disable ;;
    toggle)
      if is_active; then disable; else enable; fi
      ;;
    status)
      if is_active; then echo "ON"; else echo "OFF"; fi
      ;;
    *)
      echo "Usage: lan-mouse-toggle [on|off|toggle|status]"
      exit 1
      ;;
  esac
''
