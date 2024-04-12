{ pkgs, ... }: {
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    # extraOptions = ''
    #   auto-optimize-store = true;
    # '';
  };
}
