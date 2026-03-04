# Use lan-mouse from flake (latest with CLI/daemon support) with pointer speed patch
inputs: final: prev: {
  lan-mouse = inputs.lan-mouse.packages.${prev.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [
      ./pointer-speed.patch
    ];
  });
}
