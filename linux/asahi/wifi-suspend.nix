# Broadcom WiFi firmware jams on D3 power transition during suspend (AsahiLinux/linux#439)
# Workaround: unload brcmfmac before sleep, reload on resume
{ pkgs, ... }: {
  powerManagement = {
    powerDownCommands = ''
      ${pkgs.kmod}/bin/rmmod brcmfmac_wcc 2>/dev/null || true
      ${pkgs.kmod}/bin/rmmod brcmfmac 2>/dev/null || true
    '';
    powerUpCommands = ''
      ${pkgs.kmod}/bin/modprobe brcmfmac
    '';
  };
}
