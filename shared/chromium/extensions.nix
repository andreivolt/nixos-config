{ inputs, pkgs, ... }:
let
  extensions = inputs.chromium-extensions.packages.${pkgs.system};
in {
  chromium.extensions = [
    extensions.ff2mpv
    extensions.dearrow
  ];
}
