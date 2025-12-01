# Vicinae launcher configuration
# Fixes the hardcoded qt5ct environment that breaks Qt apps
{
  services.vicinae = {
    enable = true;
    autoStart = true;
  };

  # Override Qt environment - vicinae hardcodes qt5ct which we don't use
  systemd.user.services.vicinae.Service.Environment = [
    "QT_QPA_PLATFORMTHEME=adwaita"
  ];
}
