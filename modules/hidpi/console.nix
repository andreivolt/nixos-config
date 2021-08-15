{ pkgs, ... }:

{
  console.packages = [ pkgs.terminus_font ];

  console.font = "ter-132n";

  # user font in initrd
  console.earlySetup = true;

  # # use maximum resolution in systemd-boot
  # boot.loader.systemd-boot.consoleMode = lib.mkDefault "max";
}
