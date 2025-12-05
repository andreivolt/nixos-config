# Phone-specific packages (on top of core.nix)
# termux-api commands come from nix-on-droid's termux packages
pkgs:
(import ./core.nix pkgs) ++ (with pkgs; [
  # Phone-only additions (if any)
])
