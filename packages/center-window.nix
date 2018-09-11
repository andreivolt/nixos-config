self: super: with super; {

center-window = writeShellScriptBin "center-window" ''
  id=$1

  IFS='x' read screen_width screen_height < <(${xorg.xdpyinfo}/bin/xdpyinfo | grep dimensions | grep -o '[0-9x]*' | head -n1)
  width=$(${xdotool}/bin/xdotool --window $id getwindowgeometry --shell | head -4 | tail -1 | sed 's/[^0-9]*//')
  height=$(${xdotool}/bin/xdotool --window $id getwindowgeometry --shell | head -5 | tail -1 | sed 's/[^0-9]*//')

  x=$((screen_width / 2 - width / 2))
  y=$((screen_height / 2 - height / 2))

  ${wmctrl}/bin/wmctrl \
    -ri $id \
    -e 0,$x,$y,-1,-1'';

}
