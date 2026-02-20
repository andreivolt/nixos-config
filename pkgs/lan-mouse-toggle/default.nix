{
  writeShellScriptBin,
  lan-mouse,
  gnugrep,
  systemd,
}:
writeShellScriptBin "lan-mouse-toggle" ''
  LAN_MOUSE="${lan-mouse}/bin/lan-mouse"

  is_active() {
    $LAN_MOUSE cli list 2>/dev/null | ${gnugrep}/bin/grep -q "active: true"
  }

  case "''${1:-toggle}" in
    on)      $LAN_MOUSE cli activate 0 ;;
    off)     $LAN_MOUSE cli deactivate 0 ;;
    toggle)
      # Route through tray so icon updates instantly
      ${systemd}/bin/busctl --user call org.kde.StatusNotifierItem-lan-mouse /StatusNotifierItem org.kde.StatusNotifierItem Activate ii 0 0 2>/dev/null \
        || if is_active; then $LAN_MOUSE cli deactivate 0; else $LAN_MOUSE cli activate 0; fi
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
