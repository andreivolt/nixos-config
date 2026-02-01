# Blank Chromium profile desktop entry
# Uses the unwrapped package binary to avoid singleton conflicts with the main instance
{ pkgs, config, lib, ... }:
let
  chromium = "${pkgs.chromium}/bin/chromium";
  flags = lib.concatStringsSep " " (config.chromium.baseFlags ++ [
    "--user-data-dir=/tmp/chromium-blank"
    "--no-first-run"
    "--no-default-browser-check"
  ]);
in {
  home-manager.users.andrei.xdg.desktopEntries.chromium-blank = {
    name = "Chromium (Blank Profile)";
    genericName = "Web Browser";
    exec = "${chromium} ${flags} %U";
    icon = "chromium";
    terminal = false;
    categories = ["Network" "WebBrowser"];
    actions = {
      "new-window" = {
        name = "New Window";
        exec = "${chromium} ${flags}";
      };
      "new-private-window" = {
        name = "New Incognito Window";
        exec = "${chromium} ${flags} --incognito";
      };
    };
  };
}
