# aliases

alias venv='function _venv() {
    source $1/bin/activate
}; _venv'

alias pdffer='function _pdffer() {
    local tmp_file
    tmp_file=$(mktemp).pdf && \
    curl -s "$1" > "$tmp_file" && \
    zathura "$tmp_file" && \
    rm "$tmp_file"
}; _pdffer'

alias tf='function _tf() {
  termflow
}; _tf'
