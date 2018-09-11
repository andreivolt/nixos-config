self: super: with super; {

whattimeisit = writeShellScriptBin "whattimeisit" ''
  exec &>/dev/null setsid \
    ${libnotify}/bin/notify-send \
      "$(date +'%l:%M %p' | sed 's/^ //')"'';

}
