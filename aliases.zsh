# aliases

alias mkvenv='function _mkvenv() {
  python$1 -m venv .venv
}; _mkvenv'

alias venv='function _venv() {
    source $1/bin/activate
}; _venv'

alias rmvenv='function _rmvenv() {
  rm -r $1
}; _rmvenv'

alias pdffer='function _pdffer() {
    local tmp_file
    tmp_file=$(mktemp).pdf && \
    curl -s "$1" > "$tmp_file" && \
    zathura "$tmp_file" && \
    rm "$tmp_file"
}; _pdffer'


alias tf='termflow'
