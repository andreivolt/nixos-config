{
  services.xserver.windowManager = {
    default = "xmonad";
    xmonad = { enable = true; enableContribAndExtras = true; };
  };

  environment.variables = {
    XMONAD_CONFIG_DIR = builtins.toString ./.;
    XMONAD_DATA_DIR = "/tmp"; XMONAD_CACHE_DIR = "/tmp";
  };
}
