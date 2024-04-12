{
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.1;
    autohide-time-modifier = 0.1;
    expose-animation-duration = 0.1;
    mineffect = "scale";
    minimize-to-application = true;
    orientation = "bottom";
    show-recents = false;
    showhidden = true;
    tilesize = 48;
    wvous-br-corner = 5; # bottom-right corner starts screensaver
    wvous-tr-corner = 2; # top-right corner show windows
  };

  system.activationScripts.postUserActivation.text = ''
    pkill -f CoreServices/Dock.app
  '';
}
