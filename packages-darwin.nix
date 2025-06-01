pkgs:
with pkgs;
  [
    iproute2mac
  ]
  ++ (with darwin; [
    asitop
    coreutils
    duti
    findutils
    gawk
    gnugrep
    gnused
    libiconvReal
    lsusb
    m-cli
    mas
    monitorcontrol
    plistwatch
    pngpaste
    psutils
    terminal-notifier
    trash
    util-linux
    watch
    xcodes
  ])
