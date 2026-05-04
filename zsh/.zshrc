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

## Load completions
autoload -Uz compinit && compinit

## Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

## Keybindings
# bindkey -e
bindkey -v

# CLI Alias 

## Rust utility: bat eza fd fzf ripgrep tree zoxide
alias cat="bat --style=plain"
alias ls="eza"
alias curltime="curl -o /dev/null -s -w 'Establish Connection: %{time_connect}s\nTTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n'"
alias jqsanitize="jq -R . | jq -s . | jq -r 'join(\"\")'"
alias pbpastejq="pbpaste | jq -R . | jq -s . | jq -r ."
alias gcleanup="git branch | egrep -v \"(^\*|master|main)\" | xargs git branch -D"


# Function
disappointed() { echo -n " ಠ_ಠ " |tee /dev/tty| xclip -selection clipboard; }

flip() { echo -n "（╯°□°）╯ ┻━┻" |tee /dev/tty| xclip -selection clipboard; }

shrug() { echo -n "¯\_(ツ)_/¯" |tee /dev/tty| xclip -selection clipboard; }

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

export NVM_DIR="$HOME/.nvm"
[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && \. "$(brew --prefix)/opt/nvm/nvm.sh"
[ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm"

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=("$HOME/.docker/completions" $fpath)
# End of Docker CLI completions

export PATH=$PATH:/usr/local/bin/python3
export PATH=/Library/Frameworks/Python.framework/Versions/3.13/bin:$PATH

export PATH="$PATH:$HOME/go/bin"

export PATH="$HOMEBREW_REPOSITORY/opt/libpq/bin:$PATH"
export PATH="$HOMEBREW_REPOSITORY/opt/curl/bin:$PATH"

# echo eval "$(/opt/homebrew/bin/brew shellenv)" eval export HOMEBREW_PREFIX="/opt/homebrew";
# export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
# export HOMEBREW_REPOSITORY="/opt/homebrew";
# eval "$(/usr/bin/env PATH_HELPER_ROOT="/opt/homebrew" /usr/libexec/path_helper -s)"
# [ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}";
# export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
# 
# eval "$(/opt/homebrew/bin/brew shellenv)"
# echo eval "$(/opt/homebrew/bin/brew shellenv)" eval 
# 
# eval "$(/opt/homebrew/bin/brew shellenv)"


# Added by Toolbox App
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# Added by ForgeCode installer
export PATH="$HOME/.local/bin:$PATH"

# Binary
export PATH=/usr/local/bin/:$PATH
# complete -C '/usr/local/bin/aws_completer' aws
complete -C '$HOMEBREW_REPOSITORY/bin/aws_completer' aws

# Shell Integration
# Set up Homebrew environment
eval "$(/opt/homebrew/bin/brew shellenv)"
# Optional: Set up MANPATH and INFOPATH if needed
# export MANPATH=":${MANPATH#:}"
# export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
eval "$(fzf --zsh)"
eval "$(zoxide init zsh --cmd cd)"
eval "$(starship init zsh)"

source $HOME/.gdt.zshrc

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git)

source $ZSH/oh-my-zsh.sh

# >>> forge initialize >>>
# !! Contents within this block are managed by 'forge zsh setup' !!
# !! Do not edit manually - changes will be overwritten !!

# Add required zsh plugins if not already present
if [[ ! " ${plugins[@]} " =~ " zsh-autosuggestions " ]]; then
    plugins+=(zsh-autosuggestions)
fi
if [[ ! " ${plugins[@]} " =~ " zsh-syntax-highlighting " ]]; then
    plugins+=(zsh-syntax-highlighting)
fi

# Load forge shell plugin (commands, completions, keybindings) if not already loaded
if [[ -z "$_FORGE_PLUGIN_LOADED" ]]; then
    eval "$(forge zsh plugin)"
fi

# Load forge shell theme (prompt with AI context) if not already loaded
if [[ -z "$_FORGE_THEME_LOADED" ]]; then
    eval "$(forge zsh theme)"
fi
# <<< forge initialize <<<
