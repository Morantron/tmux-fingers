for id in $(tmux list-windows -F "#{window_id}:#{pane_id}:#{window_name}" | grep -v ":$1:" | grep "fingers" | cut -f1 -d:); do
    tmux kill-window -t $id
done
