#!/usr/bin/env zsh

# Define colors and symbols
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"

# Function to apply a setting and print status
apply_setting() {
    local description="$1"
    # Shift arguments to get the command and its parameters
    shift
    local command_args=("$@")

    echo -n "  Applying: ${description}... "
    # Execute the command, suppressing its output
    "${command_args[@]}" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        # Using -e to interpret escape codes for color
        echo -e "${CHECK} Done"
    else
        echo -e "${CROSS} Failed"
    fi
}

echo "Configuring Finder settings for macOS..."

apply_setting "Show all filename extensions" defaults write NSGlobalDomain AppleShowAllExtensions -bool true
apply_setting "Show hidden files" defaults write com.apple.finder AppleShowAllFiles -bool true
apply_setting "Set default view to Columns" defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
apply_setting "Show Path Bar" defaults write com.apple.finder ShowPathbar -bool true
apply_setting "Show Status Bar" defaults write com.apple.finder ShowStatusBar -bool true
apply_setting "Keep folders on top" defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Restart Finder separately
echo -n "  Restarting Finder... "
killall Finder > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${CHECK} Done"
else
    echo -e "${CROSS} Failed"
fi

echo "Finder configuration complete." 