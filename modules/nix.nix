{ pkgs, ... }: {
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    # extraOptions = ''
    #   auto-optimize-store = true;
    # '';
  };
}
