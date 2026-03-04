# WasIstLos: tray icon click toggles window visibility
inputs: final: prev: {
  wasistlos = prev.wasistlos.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [
      ./tray-toggle.patch
    ];
  });
}
