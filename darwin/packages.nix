pkgs:
with pkgs;
  [
    iproute2mac
  ]
  ++ (with darwin; [
    # andrei.pbpaste-html # TODO: Swift/Cocoa SDK compatibility issues
    andrei.impbcopy
    andrei.videosnap
    fswatch
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
    psutils
    terminal-notifier
    trash
    util-linux
    watch
    xcodes
  ])
