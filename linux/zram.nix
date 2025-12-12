# zram swap with lz4 compression for maximum responsiveness
# Compressed RAM swap is ~10-100x faster than NVMe, negligible CPU overhead
{ ... }: {
  zramSwap = {
    enable = true;
    algorithm = "lz4";
  };

  # Optimize for zram (Pop!_OS values)
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;                 # zram is fast, swap early
    "vm.watermark_boost_factor" = 0;       # disable watermark boosting
    "vm.watermark_scale_factor" = 125;     # earlier memory reclaim
    "vm.page-cluster" = 0;                 # no readahead for zram (no seek penalty)
  };
}
