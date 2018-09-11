self: super: with super; {

google-search = let _ = writeScript "_" ''
  #!/usr/bin/env bash

  exec \
    ${surfraw}/bin/surfraw google "$*"'';
in stdenv.lib.overrideDerivation surfraw (attrs: {
  postInstall = "cp ${_} $out/bin/google-search"; });

}
