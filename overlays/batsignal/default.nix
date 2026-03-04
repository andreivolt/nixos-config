# Fix batsignal signal handler signature for newer gcc
inputs: final: prev: {
  batsignal = prev.batsignal.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [
      ./signal-handler.patch
    ];
  });
}
