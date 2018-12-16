{
  environment.etc."tmux/tmux.conf".text = ''
    bind -n S-Left previous-window
    bind -n S-Right next-window
    bind-key -n S-Up swap-window -t -1
    bind-key -n S-Down swap-window -t +1
    set -g default-terminal "screen-256color"
    set -g history-limit 99999
    set -g status-interval 5
    set -g status-justify centre
    set -g status-position top
    set -g status-right '#[fg=yellow] #(date +"%A, %d %B %Y - %R") #[default]'
    set -g visual-activity off
    set -s escape-time 0
    set-option -g base-index 1
    set-option -g message-bg brightred
    set-option -g message-fg white
    set-option -g pane-active-border-bg black
    set-option -g pane-active-border-fg green
    set-option -g pane-border-bg black
    set-option -g pane-border-fg green
    set-option -g set-titles on
    set-option -g set-titles-string "#T"
    set-option -g status on
    set-option -g status-attr dim
    set-option -g status-bg colour235
    set-option -g terminal-overrides 'xterm*:smcup@:rmcup@'
    set-option -gw window-status-activity-bg colour235
    set-option -gw window-status-activity-fg red
    set-option -gw xterm-keys on
    set-window-option -g window-status-attr dim
    set-window-option -g window-status-bg colour235
    set-window-option -g window-status-current-attr bright
    set-window-option -g window-status-current-bg colour240
    set-window-option -g window-status-current-fg white
    set-window-option -g window-status-fg white
    set-window-option -g xterm-keys on
    setw -g aggressive-resize on
    setw -g automatic-rename
    setw -g monitor-activity on
    setw -g pane-base-index 1
    unbind-key -n C-Left
    unbind-key -n C-Right
  '';
}
