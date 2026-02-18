# Zathura document viewer configuration
{
  programs.zathura = {
    enable = true;
    options = {
      font = "Inter 11";
      recolor = true;
    };
  };

  # Desktop entry is in nixpak.nix (sandboxed wrapper)
}
