pkgs:
with pkgs;
  [
    acpi
    brightnessctl  # For brightness control keys
    eww
    grim
    hyprsunset
    input-leap  # KVM software (Synergy fork) - works with Wayland via libei
    lan-mouse  # Wayland-native keyboard/mouse sharing (both machines Linux)
    waynergy  # Wayland-native Synergy client (if server is Mac/Windows with Synergy license)
    kitty
    slurp
    wf-recorder
    wayland-pipewire-idle-inhibit  # CLI tool to prevent idle/sleep
    wofi  # Application launcher
    ydotool
    alsa-utils
    beeper
    binutils
    caprine-bin
    detox
    kdePackages.dolphin
    ffmpeg-full
    fswebcam
    gcolor3
    gnome-epub-thumbnailer
    imv
    inotify-tools
    nerd-fonts.iosevka
    nerd-fonts.iosevka-term
    jq
    iotop
    liberation_ttf
    libnotify
    libreoffice-fresh
    libsForQt5.breeze-gtk
    libsForQt5.breeze-qt5
    libsForQt5.kdegraphics-thumbnailers
    lm_sensors
    lshw
    nethogs
    osquery
    pavucontrol
    pciutils
    playerctl
    psmisc
    puppeteer-cli
    slack
    strace
    sublime4
    swaytools
    tela-icon-theme
    tidal-hifi
    trash-cli
    usbutils
    whatsapp-for-linux
    wlprop
    xdg-user-dirs
    xdragon
    ytmdesktop
    emacs
    nodejs

  ]
