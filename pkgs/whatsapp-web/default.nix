{ google-chrome
, writeShellScriptBin
}:

writeShellScriptBin "whatsapp" ''
  ${google-chrome}/bin/google-chrome-stable \
    --app=https://web.whatsapp.com \
    --user-data-dir=$HOME/.config/google-chrome/whatsapp \
    --start-fullscreen
''
