# Blank Chromium profile desktop entry
# Uses the unwrapped package binary to avoid singleton conflicts with the main instance
{ pkgs, config, lib, ... }:
let
  chromium = "${pkgs.chromium}/bin/chromium";
  args = config.chromium.baseArgs ++ [
    "--user-data-dir=/tmp/chromium-blank"
    "--no-first-run"
    "--no-default-browser-check"
  ];
  wrapper = pkgs.writeShellScript "chromium-blank" ''
    exec ${chromium} ${lib.escapeShellArgs args} "$@"
  '';
in {
  home-manager.users.andrei.xdg.desktopEntries.chromium-blank = {
    name = "Chromium (Blank Profile)";
    genericName = "Web Browser";
    exec = "${wrapper} %U";
    icon = "chromium";
    terminal = false;
    categories = ["Network" "WebBrowser"];
    actions = {
      "new-window" = {
        name = "New Window";
        exec = "${wrapper}";
      };
      "new-private-window" = {
        name = "New Incognito Window";
        exec = "${wrapper} --incognito";
      };
    };
  };
}
