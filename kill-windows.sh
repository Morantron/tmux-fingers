for id in $(tmux list-windows -F "#{window_id}:#{window_name}" | grep 'fingers' | cut -f1 -d:); do
  tmux kill-window -t $id
done
