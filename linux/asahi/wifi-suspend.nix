# Broadcom WiFi firmware workarounds for Apple Silicon
# - Power save jams firmware with brcmf_cfg80211_set_power_mgmt timeout (AsahiLinux/linux#133, #453)
# - D3 power transition during suspend jams firmware (AsahiLinux/linux#439)
{ pkgs, ... }: {
  boot.extraModprobeConfig = "options brcmfmac power_save=0";

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
