# Homebrew environment (must come first — sets $HOMEBREW_PREFIX, $HOMEBREW_REPOSITORY, updates PATH)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Keg-only binary overrides (depend on $HOMEBREW_REPOSITORY being set above)
export PATH="$HOMEBREW_REPOSITORY/opt/libpq/bin:$PATH"
export PATH="$HOMEBREW_REPOSITORY/opt/curl/bin:$PATH"

# NVM setup (uses brew --prefix, depends on brew env being loaded)
export NVM_DIR="$HOME/.nvm"
[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && \. "$(brew --prefix)/opt/nvm/nvm.sh"
[ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm"

# AWS CLI completion (uses Homebrew-installed completer)
complete -C '$HOMEBREW_REPOSITORY/bin/aws_completer' aws
