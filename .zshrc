# ==============================================================================
# CYBER STUDIO WORKSTATION // ZSH
# ==============================================================================

# CachyOS ships its own zsh defaults; keep them as the base layer.
[[ -r ~/.cachyos-config.zsh ]] && source ~/.cachyos-config.zsh

# ------------------------------------------------------------------------------
# PATH
# ------------------------------------------------------------------------------
# $HOME, not a hardcoded /home/<user> path -- this file ships to other machines.
export PATH="$HOME/.local/bin:$PATH"

# ------------------------------------------------------------------------------
# PROMPT (Starship)
# ------------------------------------------------------------------------------
# starship reads $STARSHIP_CONFIG, else ~/.config/starship.toml. It does NOT
# look inside ~/.config/starship/. Without this export the repo's prompt config
# is never loaded and starship silently uses its stock prompt.
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
command -v starship >/dev/null && eval "$(starship init zsh)"

# ------------------------------------------------------------------------------
# SYSTEM TELEMETRY ON LOGIN
# ------------------------------------------------------------------------------
# Interactive top-level shells only: skip inside tmux, editors, and any
# non-interactive invocation, where a banner is just noise in captured output.
if [[ -o interactive && -t 1 && -z "${TMUX:-}" && -z "${NVIM:-}" && -z "${VIMRUNTIME:-}" ]]; then
    command -v fastfetch >/dev/null && fastfetch
fi

# ------------------------------------------------------------------------------
# MODERN CLI REPLACEMENTS
# ------------------------------------------------------------------------------
if command -v zoxide >/dev/null; then
    eval "$(zoxide init zsh)"
    alias cd="z"
fi

# Stop eza painting world-writable directories with a solid background block.
export LS_COLORS="ow=01;36:tw=01;36"

if command -v eza >/dev/null; then
    alias ls="eza --icons --git --group-directories-first"
    alias ll="eza --icons --git --group-directories-first -l"
    alias la="eza --icons --git --group-directories-first -la"
    alias tree="eza --icons --git --tree --level=2"
fi
export PATH="$HOME/.npm-global/bin:$PATH"
