{pkgs, ...}: {
  home-manager.sharedModules = [
    {
      programs.tmux = {
        enable = true;
        prefix = "C-a";
        baseIndex = 1;
        escapeTime = 0;
        historyLimit = 99999;
        keyMode = "vi";
        mouse = true;

        plugins = with pkgs.tmuxPlugins; [
          {
            plugin = resurrect;
            extraConfig = ''
              set -g @resurrect-capture-pane-contents 'on'
              set -g @resurrect-strategy-nvim 'session'
              set -g @resurrect-strategy-vim 'session'
            '';
          }
          {
            plugin = continuum;
            extraConfig = ''
              set -g @continuum-restore 'on'
              set -g @continuum-save-interval '10'
              set -g @continuum-boot 'on'
            '';
          }
        ];

        extraConfig = ''
          set -g default-terminal $TERM
          set -g history-file ~/.local/state/tmux_history
          set -g focus-events on

          set -g renumber-windows on
          set -g automatic-rename on
          set -g allow-rename on
          set -g set-titles on

          set -g monitor-activity on
          set -g display-time 500
          set -g wrap-search off
          set -g aggressive-resize on
          set -g allow-passthrough on

          bind -n MouseDrag1Status swap-window -d -t=
          bind -n C-M-Left swap-window -t -1\; select-window -t -1
          bind -n C-M-Right swap-window -t +1\; select-window -t +1
          bind -r < swap-window -t -1\; select-window -t -1
          bind -r > swap-window -t +1\; select-window -t +1

          bind C-a send-prefix
          bind C-a last-window
          bind C-p prev
          bind C-n next

          bind h select-pane -L
          bind j select-pane -D
          bind k select-pane -U
          bind l select-pane -R

          unbind [
          bind v copy-mode
          bind -T copy-mode-vi v send -X begin-selection
          bind -T copy-mode-vi y send -X copy-selection
          bind -T copy-mode-vi C-v send -X rectangle-toggle \; send-keys -X begin-selection

          bind '"' split -c "#{pane_current_path}"
          bind % split -h -c "#{pane_current_path}"
          bind c new-window -a -c "#{pane_current_path}"

          bind C-j choose-tree
          bind b break-pane -d
          bind r source-file ~/.config/tmux/tmux.conf \; display reloaded

          set -g status-style bg=default,fg=colour7
          set -g status-left ""
          set -g status-right ""
          set -g status-justify centre

          set -g window-status-style bg=default,fg=colour238
          set -g window-status-current-style bg=colour235,fg=colour241
          set -g window-status-separator ' '
          set -g window-status-format "#{?window_activity_flag,#[bg=colour17#,fg=colour0],#[bg=colour235#,fg=colour245]} #I #{?window_activity_flag,#[bg=colour16#,fg=colour0],#[bg=default#,fg=colour245]} #{p12:#{=/12/…/:window_name}}"
          set -g window-status-current-format '#[bg=colour244,fg=colour15] #I #[bg=default,fg=colour15] #{p12:#{=/12/…/:window_name}}'

          set -g message-style bg=colour8,fg=colour15

          set -g pane-border-format ""
          set -g pane-border-style fg=colour240
          set -g pane-active-border-style fg=colour2

          set-hook -g after-split-window 'set-option -w pane-border-status top'
          set-hook -g after-new-window 'set-option -w pane-border-status off'
          set-hook -g pane-exited 'if-shell "[ #{window_panes} -eq 1 ]" "set-option -w pane-border-status off"'

          set -g default-command $SHELL
        '';
      };
    }
  ];
}
