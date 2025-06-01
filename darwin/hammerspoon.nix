{inputs, ...}: {
  homebrew.casks = ["hammerspoon"];

  system.defaults.CustomUserPreferences."org.hammerspoon.Hammerspoon" = {
    MJShowMenuIconKey = false; # hide menu bar icon
    MJKeepConsoleOnTopKey = true; # console always on top
  };

  home-manager.users.andrei.home.file.".hammerspoon/Spoons/SpoonInstall.spoon/init.lua".source = "${inputs.hammerspoon-spoons}/Source/SpoonInstall.spoon/init.lua";
}
