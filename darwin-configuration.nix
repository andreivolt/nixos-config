{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nodejs
    fastlane
    ruby_2_5
  ];
  
  environment.variables = {
    "LC_ALL" = "en_us.UTF-8";
    "LANG" = "en_us.UTF-8";
  };

  programs.zsh.enable = true;

  system.stateVersion = 2;
  
  nix.maxJobs = 1;
  nix.buildCores = 1;
}


