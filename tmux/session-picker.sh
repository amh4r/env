#!/usr/bin/env bash
# Fuzzy-find tmux sessions sorted by most recently used.
# Bound to <prefix> C-f in .tmux.conf.
current=$(tmux display-message -p '#S')
tmux list-sessions -F '#{session_last_attached} #{session_name}' \
  | LC_ALL=C sort -rn \
  | cut -d' ' -f2- \
  | grep -xv "$current" \
  | fzf --reverse \
  | xargs -I{} tmux switch-client -t '{}'
