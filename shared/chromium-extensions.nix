# Merges multiple --load-extension paths into a single flag.
# Chromium only honors the last --load-extension, so multiple modules
# setting commandLineArgs independently would clobber each other.
{ config, lib, ... }:
{
  options.chromium.unpackedExtensions = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Paths to unpacked Chromium extensions, merged into a single --load-extension flag.";
  };

  config.home-manager.users.andrei.programs.chromium.commandLineArgs =
    let paths = lib.concatStringsSep "," config.chromium.unpackedExtensions;
    in lib.optional (paths != "") "--load-extension=${paths}";
}
