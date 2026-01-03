# Prevent freezes during heavy builds - kill processes before swap thrashing
{
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
    extraArgs = ["--prefer" "^(nix-daemon|cc1plus|clang|ld)$"];
  };
}
