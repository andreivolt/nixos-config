{ pkgs, ... }:

{
  system.activationScripts.script.text = ''
    #!${pkgs.stdenv.shell}

    # # cursor blink rate
    # defaults write -g NSTextInsertionPointBlinkPeriodOn -float 200; defaults write -g NSTextInsertionPointBlinkPeriodOff -float 200

    # # keyboard backlight auto dim
    # defaults write com.apple.BezelServices kDimTime -int 5

    # # key repeat
    # defaults write -g KeyRepeat -int 0.02

    # # quicklook animation disable
    # defaults write -g QLPanelAnimationDuration -float 0

    # # finder icon size
    # defaults write com.apple.dock tilesize -int 64 && killall Dock

    # # screenshots disable shadow
    # defaults write com.apple.screencapture disable-shadow -bool true && killall SystemUIServer

    # # disable animations
    # defaults write com.apple.finder DisableAllAnimations -bool true

    # # disable system sounds
    # defaults write com.apple.systemsound com.apple.sound.uiaudio.enabled -int 0
    # defaults write com.apple.Finder FinderSounds -bool false

    # # trash empty warning disable
    # defaults write com.apple.Finder WarnOnEmptyTrash -bool false

    # # window resize animations disable
    # defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

    # # quicklook animation disable
    # defaults write -g QLPanelAnimationDuration -float 0

    # # finder icon size
    # defaults write com.apple.dock tilesize -int 64 && killall Dock

    # # disable auto brigthness
    # sudo launchctl stop com.apple.AmbientDisplayAgent
    # sudo defaults write /Library/Preferences/com.apple.iokit.AmbientLightSensor "Automatic Display Enabled" -bool false

    # # disable captive portal
    # sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false

    # # show file extensions
    # defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    # # show hidden
    # defaults write com.apple.Finder AppleShowAllFiles YES

    # # dock disable recent apps
    # defaults write com.apple.Dock show-recents -bool FALSE && killall Dock

    # # dock enable auto hide
    # defaults write com.apple.Dock autohide -bool true
    # defaults write com.apple.Dock autohide-time-modifier -float 0
    # defaults write com.apple.Dock autohide-delay -float 0

    # # window resize animations disable
    # defaults write -g NSWindowResizeTime -float 0.001

    # # disable system sounds
    # defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -int 0

    # # finder icon size
    # defaults write com.apple.Finder DesktopViewOptions -dict IconSize -integer 256

    # # trash
    # defaults write com.apple.Finder WarnOnEmptyTrash -bool false

    # # disable charging sound
    # defaults write com.apple.PowerChime ChimeOnNoHardware -bool true && killall PowerChime

    # # textedit default plain text
    # defaults write com.apple.TextEdit RichText -int 0

    # # screenshots disable shadow
    # defaults write com.apple.screencapture disable-shadow -bool true

    # # disable transparency
    # defaults write com.apple.universalaccess reduceTransparency -bool true
  '';
}
