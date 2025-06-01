{inputs, ...}: {
  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    caskArgs = {
      no_quarantine = true;
      # require_sha = true;
    };

    brews = import ./brews.nix;
    casks = import ./casks.nix;
    masApps = import ./masapps.nix;
    taps = [
      "homebrew/bundle"
      "homebrew/cask-versions"
      "homebrew/command-not-found"
      "homebrew/services"
      "jakehilborn/jakehilborn"
    ];
  };
}