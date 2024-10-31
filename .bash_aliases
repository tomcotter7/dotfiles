# aliases

alias monerodaemon='function _monerodaemon() {
  cd ~/Monero
  if [[ "$1" == "start" ]]; then
    ./monerod --prune-blockchain --sync-pruned-blocks --detach
  elif [[ "$1" == "stop" ]]; then
    ./monerod stop_daemon
  else
    echo "Usage: monerodaemon [start|stop]"
  fi
}; _monerodaemon'

alias monerowaller='function _monerowallet () {
  cd ~/Monero && ./monero-wallet-cli
}; _monerowallet'

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
