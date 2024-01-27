{ pkgs, ... }:

let
  theme = import (dirOf <nixos-config> + /modules/theme.nix);
in {
  home-manager.users.andrei.programs.tmux = {
    enable = true;
    escapeTime = 0;
    prefix = "C-a";
    shortcut = "a"; # TODO: ?
    aggressiveResize = true;
    customPaneNavigationAndResize = true;
    disableConfirmationPrompt = true;
    keyMode = "vi";
    newSession = true;
    baseIndex = 1;
    # tmuxinator.enable = true;
    # tmuxp.enable = true;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      pain-control
      copycat
      # better-mouse-mode
      {
        plugin = yank;
        extraConfig = "set -g @yank_selection 'primary'";
      }
      {
        plugin = resurrect;
        extraConfig = "set -g @resurrect-strategy-nvim 'session'";
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '60' # minutes
        '';
      }
    ];
    extraConfig = ''
      set -g history-limit 65535

      set -g @plugin 'tmux-plugins/tpm'
      # if "test ! -d ~/.tmux/plugins/tpm" \
      #   "run 'git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && ~/.tmux/plugins/tpm/bin/install_plugins'"

      run '~/.tmux/plugins/tpm/tpm'

      set -g @plugin 'tmux-plugins/tmux-sensible'
      set -g @plugin 'tmux-plugins/tmux-pain-control'

      set -g @plugin 'nhdaly/tmux-better-mouse-mode'
      set -g @scroll-speed-num-lines-per-scroll 1

      set -g mouse on

      set -g @plugin 'tmux-plugins/tmux-copycat'

      # fix missing DISPLAY env variable
      set -g update-environment DISPLAY

      set -g @plugin 'tmux-plugins/tmux-yank'
      set -g @yank_selection 'primary'

      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi C-v send -X rectangle-toggle
      bind -T copy-mode-vi y send -X copy-selection

      set -g escape-time 0
      set -g renumber-windows on
      set -g monitor-activity on
      set -g set-titles on
      set -g set-titles-string "#T"

      set -g status-left '''
      set -g status-right ' #S '
      set -g window-status-format ' #I: #W '
      set -g window-status-current-format ' #I: #W '

      set -g status-style bg='#${theme.dark.inactive.background}',fg='#${theme.dark.inactive.foreground}'
      setw -g window-status-activity-style bg='#${theme.dark.urgent.background}',fg='#${theme.dark.urgent.foreground}'
      setw -g window-status-current-style  bg='#${theme.dark.active.background}',fg='#${theme.dark.active.foreground}'

      set status-justify left

      setw -g pane-base-index 1
      # set -g base-index 1

      set -g prefix C-a
      setw -g mode-keys vi
      set -g mode-keys vi

      bind C-o previous-window
      bind C-i next-window

      bind s split-window -v
      bind v split-window -h

      # reorder windows with mouse
      bind-key -n MouseDrag1Status swap-window -d -t=

      unbind p
      bind p paste-buffer

      set -g status-position top
    '';
  };
}
