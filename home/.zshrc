# Zsh configuration — i3dots (linked to ~/.zshrc by install.sh).
# Machine-specific additions go in ~/.zshrc.local (not tracked by git).

# Apply active Pywal terminal palette immediately on shell startup
[[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/wal/sequences" ]] && cat "${XDG_CACHE_HOME:-$HOME/.cache}/wal/sequences"

# System info before Powerlevel10k instant prompt
command -v fastfetch >/dev/null && fastfetch

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- Oh My Zsh (installed by install.sh in ~/.oh-my-zsh) ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)
[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- Aliases ---
alias ls='ls -sal'
alias clock='tty-clock -c -C 6 -b -D -t'

# --- Tools ---
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"
command -v atuin >/dev/null && eval "$(atuin init zsh)"

# --- Optional tools ---
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
[[ -d "$HOME/.spicetify" ]] && path+=("$HOME/.spicetify")

if command -v rbenv >/dev/null; then
  eval "$(rbenv init - zsh)"
fi

if [[ -x "$HOME/miniforge3/bin/conda" ]]; then
  __conda_setup="$("$HOME/miniforge3/bin/conda" 'shell.zsh' 'hook' 2>/dev/null)"
  if [[ $? -eq 0 ]]; then
    eval "$__conda_setup"
  elif [[ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]]; then
    . "$HOME/miniforge3/etc/profile.d/conda.sh"
  else
    path=("$HOME/miniforge3/bin" $path)
  fi
  unset __conda_setup
fi

# --- Machine-specific settings ---
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local


# Added by Antigravity CLI installer
export PATH="/home/ale/.local/bin:$PATH"

# opencode
export PATH=/home/ale/.opencode/bin:$PATH
