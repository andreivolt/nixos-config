{
  console.font = "latarcyrheb-sun32";
  # user font in initrd
  console.earlySetup = true;
  # # use maximum resolution in systemd-boot
  # boot.loader.systemd-boot.consoleMode = lib.mkDefault "max";
}
