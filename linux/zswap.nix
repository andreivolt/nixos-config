# zswap: compressed cache in front of real swap
#
# Unlike zram (a separate swap device), zswap transparently compresses pages
# before they hit the swapfile. This gives proper page aging — coldest pages
# go to disk — avoiding the zram+swap pathology where systems OOM while real
# swap sits empty (especially bad on unified memory/iGPU like Apple Silicon).
#
# See: https://old.reddit.com/r/AsahiLinux/comments/1gy0t86/
{ ... }: {
  zramSwap.enable = false;

  # Load lz4 before zswap initializes (it's =m in Asahi kernel, so zswap
  # silently falls back to slow zstd without this)
  boot.initrd.kernelModules = [ "lz4" "lz4_compress" ];

  boot.kernelParams = [
    "zswap.enabled=1"
    "zswap.compressor=lz4"
    "zswap.max_pool_percent=12"            # 12% (~1.9GB) instead of default 20% (~3.1GB) — reclaim 1.2GB RAM
    "zswap.shrinker_enabled=1"             # proactively evict cold compressed pages to disk swap
  ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 100;                 # treat anon and file pages equally (zswap makes swapping cheap)
    "vm.watermark_boost_factor" = 0;       # disable watermark boosting
    "vm.watermark_scale_factor" = 125;     # earlier memory reclaim
    "vm.page-cluster" = 0;                 # no readahead (NVMe has no seek penalty)
  };
}
