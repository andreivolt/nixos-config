# Ignore XF86 keys (power button) in hyprlock password input
inputs: final: prev: {
  hyprlock = prev.hyprlock.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [
      ./ignore-xf86.patch
    ];
  });
}
