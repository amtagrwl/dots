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

echo "Configuring macOS key repeat settings for editors..."

# Enable key repeat for Cursor using the application name
apply_setting "Enable key repeat for Cursor" defaults write -app Cursor ApplePressAndHoldEnabled -bool false

# Enable key repeat for VS Code (Optional, uncomment if you use VS Code regularly)
# Note: Using the bundle identifier here as it's generally standard for VS Code
apply_setting "Enable key repeat for VS Code" defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false

# Ensure global setting is deleted so app-specific settings take effect
# This makes press-and-hold show accents by default globally, but repeat keys in the apps specified above.
# Check if the global key exists first
echo -n "  Ensuring global ApplePressAndHoldEnabled setting is deleted... "
defaults read -g ApplePressAndHoldEnabled > /dev/null 2>&1
if [ $? -eq 0 ]; then
    # Key exists, attempt to delete it
    defaults delete -g ApplePressAndHoldEnabled > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CHECK} Deleted"
    else
        echo -e "${CROSS} Failed to delete"
    fi
else
    # Key doesn't exist, which is the desired state
    echo -e "${CHECK} Already unset"
fi

echo "Editor key repeat configuration complete."
echo "Note: You may need to log out and back in or restart your Mac for these changes to take full effect."
