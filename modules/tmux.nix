let theme = import ./theme.nix;
in {
  # programs.tmux = {
  #   enable = true;

  #   extraConfig = ''
  #     set -g @plugin 'tmux-plugins/tpm'

  #     set -g @plugin 'tmux-plugins/tmux-sensible'

  #     set -g @plugin 'tmux-plugins/tmux-pain-control'

  #     set -g @plugin 'nhdaly/tmux-better-mouse-mode'
  #     set -g @scroll-speed-num-lines-per-scroll 1
  #     set -g mouse on

  #     set -g @plugin 'tmux-plugins/tmux-copycat'
  #     set -g @plugin 'tmux-plugins/tmux-yank'
  #     # bind -T copy-mode-vi v   send -X begin-selection
  #     # bind -T copy-mode-vi C-v send -X rectangle-toggle
  #     # bind -T copy-mode-vi y   send -X copy-selection
  #     unbind               p
  #     bind                 p   paste-buffer

  #     if "test ! -d ~/.tmux/plugins/tpm" \
  #       "run 'git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && ~/.tmux/plugins/tpm/bin/install_plugins'"

  #     run '~/.tmux/plugins/tpm/tpm'

  #     set  -g base-index 1
  #     set  -g renumber-windows on

  #     set  -g monitor-activity on

  #     set  -g set-titles on
  #     set  -g set-titles-string "#T"

  #     set  -g status-style                 bg='${theme.foreground}',fg='${theme.background}'
  #     set  -g status-left                  '''
  #     set  -g status-right                 ' #S '
  #     set  -g window-status-format         ' #I: #W '
  #     set  -g window-status-current-format ' #I: #W '
  #     setw -g window-status-current-style  bg='${theme.foreground}',fg='${theme.background}'
  #     setw -g window-status-activity-style bg='${theme.yellow_fg}'

  #     set  -g prefix C-a
  #     setw -g mode-keys vi
  #     set  -g mode-keys vi

  #     bind s split-window -v
  #     bind v split-window -h
  #   '';
  # };

  environment.etc."tmux.conf".text = ''
    set -g @plugin 'tmux-plugins/tpm'

    set -g @plugin 'tmux-plugins/tmux-sensible'

    set -g @plugin 'tmux-plugins/tmux-pain-control'

    set -g @plugin 'nhdaly/tmux-better-mouse-mode'
    set -g @scroll-speed-num-lines-per-scroll 1
    set -g mouse on

    set -g @plugin 'tmux-plugins/tmux-copycat'
    set -g @plugin 'tmux-plugins/tmux-yank'
    set -g @yank_selection 'primary'
    bind -T copy-mode-vi v   send -X begin-selection
    bind -T copy-mode-vi C-v send -X rectangle-toggle
    bind -T copy-mode-vi y   send -X copy-selection
    unbind p
    bind   p paste-buffer

    run '~/.tmux/plugins/tpm/tpm'

    set  -g base-index 1
    set  -g renumber-windows on
    set  -g monitor-activity on
    set  -g set-titles on
    set  -g set-titles-string "#T"

    set  -g status-left                  '''
    set  -g status-right                 ' #S '
    set  -g window-status-format         ' #I: #W '
    set  -g window-status-current-format ' #I: #W '

    set  -g status-style                 bg='${theme.dark.inactive.background}',fg='${theme.dark.inactive.foreground}'
    setw -g window-status-activity-style bg='${theme.dark.urgent.background}',fg='${theme.dark.urgent.foreground}'
    setw -g window-status-current-style  bg='${theme.dark.active.background}',fg='${theme.dark.active.foreground}'

    set status-justify left
    setw -g pane-base-index 1

    set  -g prefix C-a
    setw -g mode-keys vi
    set  -g mode-keys vi

    bind C-o previous-window
    bind C-i next-window
    bind s   split-window -v
    bind v   split-window -h


    # set -g @plugin 'tmux-plugins/tpm'

    # set -g @plugin 'tmux-plugins/tmux-sensible'

    # set -g @plugin 'tmux-plugins/tmux-pain-control'

    # set -g @plugin 'nhdaly/tmux-better-mouse-mode'
    # set -g @scroll-speed-num-lines-per-scroll 1
    # set -g mouse on

    # set -g @plugin 'tmux-plugins/tmux-copycat'
    # set -g @plugin 'tmux-plugins/tmux-yank'
    # # bind -T copy-mode-vi v   send -X begin-selection
    # # bind -T copy-mode-vi C-v send -X rectangle-toggle
    # # bind -T copy-mode-vi y   send -X copy-selection
    # unbind               p
    # bind                 p   paste-buffer

    # if "test ! -d ~/.tmux/plugins/tpm" \
    #   "run 'git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && ~/.tmux/plugins/tpm/bin/install_plugins'"

    # run '~/.tmux/plugins/tpm/tpm'

    # set  -g base-index 1
    # set  -g renumber-windows on

    # set  -g monitor-activity on

    # set  -g set-titles on
    # set  -g set-titles-string "#T"

    # set  -g status-style                 bg='${theme.foreground}',fg='${theme.background}'
    # set  -g status-left                  '''
    # set  -g status-right                 ' #S '
    # set  -g window-status-format         ' #I: #W '
    # set  -g window-status-current-format ' #I: #W '
    # setw -g window-status-current-style  bg='${theme.foreground}',fg='${theme.background}'
    # setw -g window-status-activity-style bg='${theme.yellow_fg}'

    # set  -g prefix C-a
    # setw -g mode-keys vi
    # set  -g mode-keys vi

    # bind s split-window -v
    # bind v split-window -h
  '';
}
