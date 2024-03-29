{
  system.defaults.dock = {
    autohide = true;
    autohide-time-modifier = 0.2;
    orientation = "bottom";
    mineffect = "scale";
    show-recents = false;
    showhidden = true;
    wvous-tr-corner = 2; # top-right corner show windows
    wvous-br-corner = 5; # bottom-right corner starts screensaver
    expose-animation-duration = 0.2;
    tilesize = 48;
    autohide-delay = 0.1;
  };

  system.activationScripts.postUserActivation.text = ''
    pkill -f CoreServices/Dock.app
  '';
}
