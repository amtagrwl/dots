#!/bin/sh

# Ensure ~/.gitconfig exists and includes ~/.gitconfig_dotfiles

main_config="$HOME/.gitconfig"
dotfiles_config_include_path="$HOME/.gitconfig_dotfiles"
include_directive_line="path = $dotfiles_config_include_path"

# Ensure the main config file exists
touch "$main_config"

# Check if the include directive already exists
if grep -q -F "$include_directive_line" "$main_config"; then
  echo "✔ ~/.gitconfig already includes Dotbot git settings."
  exit 0
else
  echo "🔧 Adding include directive for Dotbot git settings to ~/.gitconfig..."
  # Add a newline for separation if the file isn't empty
  if [ -s "$main_config" ]; then
    echo "" >> "$main_config"
  fi
  # Append the include section
  echo "[include]" >> "$main_config"
  echo "    $include_directive_line" >> "$main_config"
  echo "✔ Successfully added include directive."
  exit 0
fi 