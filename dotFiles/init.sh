#!/bin/bash

set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $script_dir

delete_and_link() {
    link_path=$1
    dest_path=$2
    rm -rf $link_path
    ln -s $script_dir/$dest_path $link_path
}

exists()
{
    command -v "$1" >/dev/null 2>&1
}

# Fish
echo "Initializing fish..."
delete_and_link ~/.config/fish fish
echo "  You'll need to install fish and set it as your shell manually"

# Fish
echo "Initializing kitty..."
delete_and_link ~/.config/kitty kitty
echo "  You'll need to install kitty manually"

# Git
echo "Initializing git..."
delete_and_link ~/.gitconfig gitconfig

# asciiArt
echo "Initializing asciiArt..."
delete_and_link ~/asciiArt asciiArt


if exists i3; then
  echo "Initializing i3..."
  delete_and_link ~/.i3/config i3/config
fi