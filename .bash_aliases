# aliases

# source venv/bin/activate

alias venv='source venv/bin/activate'

alias takenotes='function _takenotes() {
    cd ~/docs/work/daily-notes
    ./takenotes "$1"
}; _takenotes'

alias pdffer='function _pdffer() {
    local tmp_file
    tmp_file=$(mktemp).pdf && \
    curl -s "$1" > "$tmp_file" && \
    zathura "$tmp_file" && \
    rm "$tmp_file"
}; _pdffer'
