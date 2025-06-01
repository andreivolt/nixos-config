{
  homebrew.casks = ["hammerspoon"];

  system.defaults.CustomUserPreferences."org.hammerspoon.Hammerspoon" = {
    MJShowMenuIconKey = false; # hide menu bar icon
    MJKeepConsoleOnTopKey = true; # console always on top
  };

  home-manager.users.andrei.home.file.".hammerspoon/Spoons/SpoonInstall.spoon/init.lua".source = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/Hammerspoon/Spoons/3f6bb38a4b1d98ec617e1110450cbc53b15513ec/Source/SpoonInstall.spoon/init.lua";
    sha256 = "0bm2cl3xa8rijmj6biq5dx4flr2arfn7j13qxbfi843a8dwpyhvk";
  };
}
