# Fix ThinkPad BD PROCHOT throttling bug + undervolt for cooler temps
# https://wiki.archlinux.org/title/Lenovo_ThinkPad_X1_Carbon_(Gen_6)#Throttling_fix
{
  services.throttled = {
    enable = true;
    extraConfig = ''
      [GENERAL]
      Enabled: True
      Sysfs_Power_Path: /sys/class/power_supply/AC*/online
      Autoreload: True

      [BATTERY]
      Update_Rate_s: 30
      PL1_Tdp_W: 15
      PL1_Duration_s: 28
      PL2_Tdp_W: 20
      PL2_Duration_S: 0.002
      Trip_Temp_C: 85
      cTDP: 0
      Disable_BDPROCHOT: False

      [AC]
      Update_Rate_s: 5
      PL1_Tdp_W: 25
      PL1_Duration_s: 28
      PL2_Tdp_W: 29
      PL2_Duration_S: 0.002
      Trip_Temp_C: 95
      HWP_Mode: True
      cTDP: 0
      Disable_BDPROCHOT: False

      [UNDERVOLT.BATTERY]
      # Tested stable
      CORE: -80
      GPU: -50
      CACHE: -80
      UNCORE: -50
      ANALOGIO: 0

      [UNDERVOLT.AC]
      # -100mV caused freeze during rebuild, -90mV as compromise
      CORE: -90
      GPU: -60
      CACHE: -90
      UNCORE: -60
      ANALOGIO: 0
    '';
  };
}
