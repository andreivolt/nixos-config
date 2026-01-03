{ config, lib, ... }:
let
  hostname = config.networking.hostName;
  isRiva = hostname == "riva";
  isAmpere = hostname == "ampere";
in
{
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    fallback = true;
    connect-timeout = 1;
    stalled-download-timeout = 1;
    download-attempts = 1;
    substituters = [
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
      "https://nixos-apple-silicon.cachix.org"
    ] ++ lib.optionals isRiva [ "http://watts:5000?priority=50" ]
      ++ lib.optionals (!isAmpere) [ "http://ampere:5000" ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
      "watts:FSqfFsCS8kQ1S38CJeND7hwRgS778f5sM5yy+rdYnN8="
      "ampere:VemsKe9KxjJHofpyUnMnGC9jHo6v49nAlKVQf/1rseI="
    ];

    trusted-users = [ "root" "@wheel" ];
  };

  nix.optimise.automatic = true;
  nix.distributedBuilds = true;
  nix.extraOptions = "builders-use-substitutes = true";
}
