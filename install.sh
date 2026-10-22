#!/bin/sh
set -e

dir=$(mktemp -d)
git clone --depth 1 https://github.com/cqley/butterfly "$dir"

mkdir -p "$HOME/.config"
rm -rf "$HOME/.config/quickshell"
cp -r "$dir/quickshell" "$HOME/.config/quickshell"
rm -rf "$dir"

echo "butterfly installed to $HOME/.config/quickshell"
