self: super: with super; {

set-scratchpad = writeShellScriptBin "set-scratchpad" ''
  #!${zsh}/bin/zsh

  new_window_id=$(${xorg.xwininfo}/bin/xwininfo | sed -rn '/Window id:/ s/.*(0x[^ ]*).*/\1/p')
  old_window_id=$(${xdotool}/bin/xdotool search --classname scratchpad)

  xprop -id $old_window_id -remove WM_CLASS
  xprop -id $new_window_id -f WM_CLASS 8s -set WM_CLASS scratchpad'';

}
