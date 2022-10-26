#!/bin/bash

# dconfig stuff
# https://www.linuxshelltips.com/export-import-gnome-terminal-profile/

sudo apt update
sudo apt install tmux
sudo apt install vim
sudo apt install dconf-editor

dconf load /org/gnome/terminal/legacy/keybindings/ < ~/configuration/keys.dconf
dconf load /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/ < ~/configuration/terminal_design.dconf
