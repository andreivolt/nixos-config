{
  type = "luks";
  name = "cryptroot";
  extraOpenArgs = [
    "--allow-discards"
    "--perf-no_read_workqueue"
    "--perf-no_write_workqueue"
  ];
  settings.allowDiscards = true;
  content = {
    type = "btrfs";
    extraArgs = [ "-L" "nixos" "-f" ];
    subvolumes = {
      "/root" = {
        mountpoint = "/btrfs_root";
        mountOptions = [ "noatime" "compress=zstd" ];
      };
      "/nix" = {
        mountpoint = "/nix";
        mountOptions = [ "noatime" "compress=zstd" ];
      };
      "/persist" = {
        mountpoint = "/persist";
        mountOptions = [ "noatime" "compress=zstd" ];
      };
      "/home" = {
        mountpoint = "/home";
        mountOptions = [ "noatime" "compress=zstd" ];
      };
      "/log" = {
        mountpoint = "/var/log";
        mountOptions = [ "noatime" "compress=zstd" ];
      };
      "/swap" = {
        mountpoint = "/swap";
        swap.swapfile.size = "4G";
      };
    };
  };
}
