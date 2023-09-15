pkgs: with pkgs; [
  Rocket # emoji
  # darwin.iproute2mac # TODO build error
  # darwin.xcbuild # TODO
  # darwin.xcode-install # TODO
  # fast-cli # TODO npm
  # localtunnel # TODO npm
  # pagekite # TODO
  # webtorrent_desktop # linux
  # wrk2 # http benchmarking # linux
  # wsc
  # xcode TODO
  coreutils
  darwin.ios-deploy
  darwin.trash
  duti # macos file associations
  findutils # gnu find
  gawk
  gnugrep # gnu grep
  gnused # gnu sed
  # (procps.overrideAttrs (attrs: {
  #   postInstall = attrs.postInstall + "\n"
  #     + "rm $out/bin/top $out/share/man/man1/top.1";
  # }))
  pstree
  util-linux
  watch
  watchexec
]
