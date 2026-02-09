{
  writeShellScriptBin,
  systemd,
  procps,
  coreutils,
}:
writeShellScriptBin "lan-mouse-toggle" ''
  STATE_FILE="''${HOME}/.local/state/lan-mouse-disabled"

  is_active() {
    ${systemd}/bin/systemctl --user is-active --quiet lan-mouse
  }

  signal_waybar() {
    ${procps}/bin/pkill -RTMIN+10 waybar 2>/dev/null || true
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
    on)      enable; signal_waybar ;;
    off)     disable; signal_waybar ;;
    toggle)
      if is_active; then disable; else enable; fi
      signal_waybar
      ;;
    status)
      if is_active; then echo "ON"; else echo "OFF"; fi
      ;;
    waybar)
      if is_active; then
        echo '{"text": "󰍽", "tooltip": "Lan Mouse: ON", "class": "active"}'
      else
        echo '{"text": "󰍽", "tooltip": "Lan Mouse: OFF", "class": "inactive"}'
      fi
      ;;
    *)
      echo "Usage: lan-mouse-toggle [on|off|toggle|status|waybar]"
      exit 1
      ;;
  esac
''
