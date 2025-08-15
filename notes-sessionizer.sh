#!/usr/bin/env bash

daily_note="$HOME/Documents/notes/daily/$(date +%F).md"

selected=$(fzf < <(
    echo "$daily_note"
    find "$HOME/Documents/notes" -mindepth 1 -maxdepth 1 -type f
))

if [[ -n $selected ]]; then
  nvim "$selected" 
fi



