# Chrome/Chromium feature flags (--enable-features).
# Separate from command-line args (chromium.baseArgs) because
# feature flags are experimental toggles tied to Chrome versions.
#
# Note: Chrome does NOT merge multiple --enable-features args
# (last one wins), so all features must be on a single line.
{ lib, pkgs, ... }:
let
  features = [
    "CompressionDictionaryTransport"
    "CompressionDictionaryTransportBackend"
    "FluentOverlayScrollbar"
    "HappyEyeballsV3"
    "ParallelDownloading"
    "ServiceWorkerAutoPreload"
    "WaylandWindowDecorations"
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    "AcceleratedVideoDecodeLinuxGL"
    "AcceleratedVideoDecodeLinuxZeroCopyGL"
  ];
in {
  home-manager.users.andrei.programs.chromium.commandLineArgs = [
    "--enable-features=${lib.concatStringsSep "," features}"
  ];
}
