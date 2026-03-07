{ inputs, pkgs, ... }:
let
  names = builtins.filter (s: builtins.isString s && s != "")
    (builtins.split "\n" (builtins.readFile ./extensions.list));
in {
  chromium.extensions =
    map (name: inputs.${name}.packages.${pkgs.stdenv.hostPlatform.system}.default) names;
}
