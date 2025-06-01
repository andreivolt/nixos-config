{...}: {
  system.activationScripts.autoBrightness.text = ''
    echo 'disable auto brightness'
    defaults write /Library/Preferences/com.apple.iokit.AmbientLightSensor "Automatic Display Enabled" -bool false
  '';
}