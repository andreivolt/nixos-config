# Rofi launcher configuration
{ pkgs, ... }: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    terminal = "kitty --single-instance";
    font = "Roboto 13";
    theme = "~/.config/rofi/theme.rasi";
    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
      icon-theme = "Papirus-Dark";
      display-drun = "";
      display-combi = ">";
      drun-display-format = "{name}";
      drun-show-actions = true;
      hover-select = true;
      me-select-entry = "";
      me-accept-entry = "MousePrimary";
      kb-remove-to-eol = "";
      kb-accept-entry = "Return,KP_Enter";
      kb-row-down = "Down,Control+j";
      kb-row-up = "Up,Control+k";
    };
  };

  xdg.configFile."rofi/theme.rasi".source = ./theme.rasi;

  # App launcher with combi mode (windows + apps)
  # Shows running windows first, then apps - selecting a window focuses it
  home.packages = [
    (pkgs.writeShellScriptBin "rofi-launch" ''
      rofi -show combi -combi-modi "window,drun" -modi combi
    '')
  ];
}
