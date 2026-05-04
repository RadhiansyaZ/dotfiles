#!/usr/bin/env bash

# Define the installation path (default for TPM)
TPM_PATH="$HOME/.tmux/plugins/tpm"

# 1. Clone TPM if it's not already installed
if [ ! -d "$TPM_PATH" ]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_PATH"
else
    echo "TPM is already installed."
fi

# 2. Ensure tmux is running to install plugins via command line
# This starts a detached session so we can run the TPM install script
tmux start-server

# 3. Trigger plugin installation
# The 'install_plugins' script is part of TPM and reads your .tmux.conf
echo "Installing tmux plugins..."
"$TPM_PATH/bin/install_plugins"

echo "Done! Restart tmux or source your config to see changes."
