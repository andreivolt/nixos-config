{
  services.compton = {
    enable = true;

    shadow = true;
    shadowOffsets = [ (-15) (-15) ];
    shadowOpacity = "0.7";
    # shadowExclude = [
    #   ''
    #     !(XMONAD_FLOATING_WINDOW ||
    #       (_NET_WM_WINDOW_TYPE@[0]:a = "_NET_WM_WINDOW_TYPE_DIALOG") ||
    #       (_NET_WM_STATE@[0]:a = "_NET_WM_STATE_MODAL"))
    #   ''
    # ];
    extraOptions = ''
      blur-background = true;
      #blur-background-frame = true;
      #blur-background-fixed = false;
      #blur-background-exclude = [
      #  "class_g = 'slop'";
      #];
      blur-kern = "11,11,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1";
      clear-shadow = true;
    '';
  };
}
