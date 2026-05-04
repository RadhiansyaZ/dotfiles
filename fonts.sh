#!/bin/bash

# Define fonts and version
FONTS=("FiraCode" "JetBrainsMono")
VERSION="v3.2.1"

# Determine OS and set Font Directory
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    FONT_DIR="$HOME/.local/share/fonts"
    OS_TYPE="Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    FONT_DIR="$HOME/Library/Fonts"
    OS_TYPE="macOS"
else
    echo "󰚌 Unsupported OS: $OSTYPE"
    exit 1
fi

echo "󰚚 Detected $OS_TYPE. Target: $FONT_DIR"
mkdir -p "$FONT_DIR"

for FONT in "${FONTS[@]}"; do
    # Search for any variant of the font in the dir
    if find "$FONT_DIR" -iname "*${FONT}*" | grep -q "."; then
        echo "󰄬 $FONT seems to be installed already. Skipping."
    else
        echo "󱑤 Downloading $FONT..."
        ZIP_FILE="${FONT}.zip"
        URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION}/${FONT}.zip"
        
        # Download and extract
        if curl -fLo "$ZIP_FILE" "$URL"; then
            echo "󰏖 Extracting to $FONT_DIR..."
            unzip -o "$ZIP_FILE" -d "$FONT_DIR" > /dev/null
            rm "$ZIP_FILE"
            echo "󰄬 $FONT installed."
        else
            echo "󰰱 Failed to download $FONT. Check your connection or the version tag."
        fi
    fi
done

# Clean up macOS metadata files if they exist (prevents font corruption)
find "$FONT_DIR" -name "._*" -delete 2>/dev/null

# Refresh font cache (Linux only)
if [[ "$OS_TYPE" == "Linux" ]]; then
    echo "󰑐 Refreshing Linux font cache..."
    fc-cache -f "$FONT_DIR"
fi

echo "󰄭 Installation complete for $OS_TYPE!"