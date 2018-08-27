{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ rlwrap ];

  home-manager.users.avo
    .home.sessionVariables = with config.home-manager.users.avo.xdg; {
      INPUTRC = "${configHome}/readline/inputrc";
      RLWRAP_HOME = "${cacheHome}/rlwrap";
    };

  home-manager.users.avo
    .xdg.configFile."readline/inputrc".text = ''
      set editing-mode vi

      set completion-ignore-case on
      set show-all-if-ambiguous  on

      set keymap vi
      C-r: reverse-search-history
      C-f: forward-search-history
      C-l: clear-screen
      v:   rlwrap-call-editor
    '';
}
