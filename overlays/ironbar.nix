# Use ironbar fork with window-rewrite support
inputs: final: prev: {
  ironbar = inputs.ironbar.packages.${prev.stdenv.hostPlatform.system}.default;
}
