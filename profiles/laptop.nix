# Shared laptop optimizations for portable workstations
# Imported by: hosts/watts, hosts/riva
{...}: {
  # Auto-switch power profiles based on AC/battery
  services.power-profiles-daemon.enable = true;

  # Allow CPU to idle properly (default 1024 prevents low-power states)
  boot.kernel.sysctl."kernel.sched_util_clamp_min" = 128;

  # More responsive I/O writeback (reduces UI stutter during large file ops)
  boot.kernel.sysctl."vm.dirty_ratio" = 10;
  boot.kernel.sysctl."vm.dirty_background_ratio" = 5;
}
