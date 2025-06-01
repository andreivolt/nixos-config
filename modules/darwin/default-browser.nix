{...}: {
  system.activationScripts.defaultBrowser.text = ''
    echo 'set default browser'
    sudo -u andrei /opt/homebrew/bin/defaultbrowser chrome 2>/dev/null || true
  '';
}