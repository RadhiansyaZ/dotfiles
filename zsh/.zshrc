## History
HISTSIZE=2000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Docker CLI completions must be on fpath before compinit runs.
fpath=("$HOME/.docker/completions" $fpath)

## Load completions
autoload -Uz compinit && compinit

# Platform helpers
is_macos() { [[ "$(uname)" == "Darwin" ]]; }
is_linux() { [[ "$(uname)" == "Linux" ]]; }

## Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

## Keybindings
bindkey -e
# bindkey -v

# CLI Alias 

## Rust utility: bat eza fd fzf ripgrep tree zoxide
alias cat="bat --style=plain"
alias ls="eza"
alias curltime="curl -o /dev/null -s -w 'Establish Connection: %{time_connect}s\nTTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n'"
alias jqsanitize="jq -R . | jq -s . | jq -r 'join(\"\")'"
if is_macos && command -v pbpaste >/dev/null 2>&1; then
  alias pbpastejq="pbpaste | jq -R . | jq -s . | jq -r ."
fi
alias gcleanup="git branch | egrep -v \"(^\*|master|main)\" | xargs git branch -D"


# Function
# Clipboard helpers
copy_to_clipboard() {
  if is_macos && command -v pbcopy >/dev/null 2>&1; then
    pbcopy
  elif is_linux && command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard
  else
    return 1
  fi
}

disappointed() { echo -n " ಠ_ಠ " | tee /dev/tty | copy_to_clipboard; }

flip() { echo -n "（╯°□°）╯ ┻━┻" | tee /dev/tty | copy_to_clipboard; }

shrug() { echo -n "¯\\_(ツ)_/¯" | tee /dev/tty | copy_to_clipboard; }
gdiff() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" \
  | fzf --ansi --preview "echo {} \
    | grep -o '[a-f0-9]\{7\}' \
    | head -1 \
    | xargs -I % sh -c 'git show --color=always %'" \
        --bind "enter:execute:
            (grep -o '[a-f0-9]\{7\}' \
                | head -1 \
                | xargs -I % sh -c 'git show --color=always % \
                | less -R') << 'FZF-EOF'
            {}
FZF-EOF"
}


# XDG Base Directory Specification
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

export EDITOR="zed --wait"

export PATH=$PATH:/usr/local/bin/python3
if is_macos; then
  export PATH=/Library/Frameworks/Python.framework/Versions/3.13/bin:$PATH
fi

export PATH="$PATH:$HOME/go/bin"

# Added by Toolbox App
if is_macos && [[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]]; then
  export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
fi

# Added by ForgeCode installer
export PATH="$HOME/.local/bin:$PATH"

# Binary
export PATH=/usr/local/bin/:$PATH
# complete -C '/usr/local/bin/aws_completer' aws

# Shell Integration
[[ -f "$HOME/.homebrew.zshrc" ]] && source "$HOME/.homebrew.zshrc"

source $HOME/.gdt.zshrc

eval "$(fzf --zsh)"
eval "$(zoxide init zsh --cmd cd)"
eval "$(starship init zsh)"

ZSH_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

if [[ -f "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [[ -f "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# >>> forge initialize >>>
# !! Contents within this block are managed by 'forge zsh setup' !!
# !! Do not edit manually - changes will be overwritten !!

# Add required zsh plugins if not already present
# if [[ ! " ${plugins[@]} " =~ " zsh-autosuggestions " ]]; then
#     plugins+=(zsh-autosuggestions)
# fi
# if [[ ! " ${plugins[@]} " =~ " zsh-syntax-highlighting " ]]; then
#     plugins+=(zsh-syntax-highlighting)
# fi
# ^ We are not using ohmyzsh, so we commented out the code above.

# Load forge shell plugin (commands, completions, keybindings) if not already loaded
# if [[ -z "$_FORGE_PLUGIN_LOADED" ]]; then
#     eval "$(forge zsh plugin)"
# fi

# Load forge shell theme (prompt with AI context) if not already loaded
# if [[ -z "$_FORGE_THEME_LOADED" ]]; then
#     eval "$(forge zsh theme)"
# fi
# <<< forge initialize <<<
