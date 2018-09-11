self: super: with super; {

volumectl = writeShellScriptBin "volumectl" ''
  set() {
    ${pamixer}/bin/pamixer --unmute

    case $1 in
      +*) ${pamixer}/bin/pamixer --increase ''${1/+/} ;;
      -*) ${pamixer}/bin/pamixer --decrease ''${1/-/} ;;
    esac
  }

  get() {
    ${pamixer}/bin/pamixer --get-volume
  }

  toggle-mute() {
    ${pamixer}/bin/pamixer --toggle-mute
  }

  case $1 in
    up) set +2 ;;
    down) set -2 ;;
    toggle-mute) toggle-mute;;
  esac

  ${libnotify}/bin/notify-send \
    --app-name volume \
    "volume" $(get)'';

}
