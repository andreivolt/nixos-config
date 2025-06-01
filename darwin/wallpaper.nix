{...}: {
  system.activationScripts.wallpaper.text = ''
    echo 'set desktop wallpaper'
    sudo -u andrei osascript -e 'tell application "Finder" to set desktop picture to POSIX file "/System/Library/Desktop Pictures/Solid Colors/Black.png"' 2>/dev/null || true
  '';
}