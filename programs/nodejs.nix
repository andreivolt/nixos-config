{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ nodejs ];

  home-manager.users.avo
    .home.sessionVariables.NPM_CONFIG_USERCONFIG = with config.home-manager.users.avo.xdg;
      "${configHome}/npm/config";

  home-manager.users.avo
    .xdg.configFile."npm/config".text = lib.generators.toKeyValue {} (with config.home-manager.users.avo.xdg; {
      prefix      = "${dataHome}/npm/packages";
      cache       = "${cacheHome}/npm/packages";
      tmp         = "${builtins.getEnv "XDG_RUNTIME_DIR"}/npm";
      init-module = "${configHome}/npm/config/npm-init.js";
    });
}
