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


grec() {
  local count=${1:-5}
  git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)' | head -n "$count"
}


vd-open-url() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: vd-open-url <cell_content>" >&2
        return 1
    fi

    local cell_content="$1"

    if [[ "$cell_content" == \[*\] && "$cell_content" == *\] ]]; then
        echo "$cell_content" | python3.13 -c "import sys, ast, shlex; [print(shlex.quote(u)) for u in ast.literal_eval(sys.stdin.read())]" | xargs -n 1 open
    else
        open "$cell_content"
    fi
}

export -f vd-open-url &>/dev/null

