#!/bin/env bash

FISH_SHELL_DESTINATION=~/.config/fish/functions

echo "Installing..."
install fish_prompt.fish $FISH_SHELL_DESTINATION
echo "Done!"
