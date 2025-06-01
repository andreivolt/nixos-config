{...}: {
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

    brews = import ../homebrew-brews.nix;
    casks = import ../homebrew-casks.nix;
    masApps = import ../homebrew-masapps.nix;
    taps = [
      "homebrew/bundle"
      "homebrew/cask-versions"
      "homebrew/command-not-found"
      "homebrew/services"
      "jakehilborn/jakehilborn"
    ];
  };
}