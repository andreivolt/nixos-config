# Zathura document viewer configuration
{
  programs.zathura = {
    enable = true;
    options = {
      font = "Roboto 11";
      recolor = true;
    };
  };

  # Desktop entry is in nixpak.nix (sandboxed wrapper)
}
