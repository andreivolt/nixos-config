{
  config,
  pkgs,
  ...
}: {
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.1;
    autohide-time-modifier = 0.1;
    enable-spring-load-actions-on-all-items = false;
    # defaults write "com.apple.dock" "enterMissionControlByTopWindowDrag" '0'
    show-process-indicators = false;
    expose-animation-duration = 0.1;
    mineffect = "scale";
    minimize-to-application = true;
    orientation = "bottom";
    # scroll-to-open = true; # TODO
    show-recents = false;
    showhidden = true;
    tilesize = 48;
    wvous-br-corner = 5; # bottom-right corner starts screensaver
    wvous-tr-corner = 2; # top-right corner show windows
  };
}
