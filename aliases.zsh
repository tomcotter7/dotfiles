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
alias cc="claude"


grec() {
  local count=${1:-10}
  git checkout $(git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)' | head -n "$count" | fzf)
}

alias groot='cd "$(git rev-parse --show-toplevel)"'

# gwt <type> <name>: worktree at ../<repo>-<name> on branch <type>/<name>
unalias gwt 2>/dev/null # omz git plugin: gwt='git worktree'
gwt() {
  [[ $# -eq 2 ]] || { echo "usage: gwt <feat|fix|...> <name>" >&2; return 1; }
  local root
  # main checkout, so running from inside a worktree doesn't give repo-a-b
  root=$(git rev-parse --path-format=absolute --git-common-dir) || return 1
  root=${root:h}
  git -C "$root" worktree add "${root:h}/${root:t}-$2" -b "$1/$2"
}

