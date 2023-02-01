#!/bin/bash

# dconfig stuff
# https://www.linuxshelltips.com/export-import-gnome-terminal-profile/

sudo apt update && sudo apt upgrade -y
sudo apt install tmux vim dconf-editor tree valgrind build-essential manpages-dev clang -y

# Install code:
sudo apt install wget gpg -y
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg]
https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
sudo apt update -y
sudo apt install code -y

# Yocto dependencies
$ sudo apt install gawk wget git diffstat unzip texinfo gcc build-essential chrpath socat cpio python3 python3-pip
python3-pexpect xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev xterm
python3-subunit mesa-common-dev zstd liblz4-tool -y

# Install visual studio code
dconf load /org/gnome/terminal/legacy/keybindings/ < ~/configuration/keys.dconf
dconf load /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/ < ~/configuration/terminal_design.dconf
