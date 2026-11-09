#!/usr/bin/env bash
# Set up a new Mac from this repo. Safe to run again.
set -euo pipefail

DOTFILES="$HOME/dotfiles"
[[ "$(cd "$(dirname "$0")" && pwd)" == "$DOTFILES" ]] || { echo "clone this repo to $DOTFILES first" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# link SRC DST: symlink DST -> SRC, moving any real file at DST to DST.bak
link() {
    local src="$DOTFILES/$1" dst="$2"
    [[ "$(readlink "$dst" 2>/dev/null)" == "$src" ]] && return
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        mv "$dst" "$dst.bak"
        echo "backed up $dst -> $dst.bak"
    fi
    ln -sfn "$src" "$dst"
    echo "linked $dst"
}

install_packages() {
    if ! have brew; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    eval "$(/opt/homebrew/bin/brew shellenv)"
    brew bundle --no-upgrade --file="$DOTFILES/Brewfile"

    [[ -d "$HOME/.oh-my-zsh" ]] || RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    local plugin="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    [[ -d "$plugin" ]] || git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin"

    # .zshrc sources ~/.cargo/env with no guard
    [[ -f "$HOME/.cargo/env" ]] || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    have uv || curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
    have claude || curl -fsSL https://claude.ai/install.sh | bash
    export PATH="$HOME/.local/bin:$PATH"

    local installed pkg
    installed=$(pipx list --short | cut -d' ' -f1)
    while read -r pkg; do
        grep -qx "$pkg" <<<"$installed" || pipx install "$pkg" || echo "WARN: pipx install $pkg failed" >&2
    done < "$DOTFILES/pipx.txt"

    [[ -d "$HOME/.config/nvim" ]] || git clone git@github.personal.com:tomcotter7/nvim-config.git "$HOME/.config/nvim"
}

link_dotfiles() {
    link .zshrc ~/.zshrc
    link .tmux.conf ~/.tmux.conf
    link aliases.zsh ~/.oh-my-zsh/custom/aliases.zsh
    link config ~/Library/Application\ Support/com.mitchellh.ghostty/config
    link config.toml ~/.config/hunk/config.toml
    link zathurarc ~/.config/zathura/zathurarc

    local f
    for f in CLAUDE.md settings.json statusline.sh team-config.md \
        commands/change.md scripts/file-change-tracker.sh \
        skills/dab-autopilot skills/designing-tufte-graphics skills/grill-me skills/incident skills/playground skills/termflow; do
        link "claude/$f" "$HOME/.claude/$f"
    done

    crontab "$DOTFILES/crontab"
}

install_claude_plugins() {
    claude plugin marketplace add dbt-labs/dbt-agent-skills || true
    local p
    for p in $(jq -r '.enabledPlugins | keys[]' "$DOTFILES/claude/settings.json"); do
        claude plugin install "$p" || echo "WARN: claude plugin install $p failed" >&2
    done
}

case "${1:-all}" in
    links) link_dotfiles ;;
    all) install_packages; link_dotfiles; install_claude_plugins ;;
    *) echo "usage: $0 [all|links]" >&2; exit 1 ;;
esac

cat <<'EOF'

Done. Manual steps:
  - SSH keys + ~/.ssh/config: the github.personal.com alias (dotfiles, nvim-config) and github.com (depop/tools tap). Do this BEFORE running this script.
  - Clone ~/Personal/termflow, ~/Personal/dabctl and ~/Documents/claude-team-workflows, then run their installs.
  - Copy ~/.secrets and ~/.zshrc.local. Install Rancher Desktop. Set up depop-dbt.
  - Open a new shell, then run `claude` and log in.
EOF
