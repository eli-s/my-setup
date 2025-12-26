#!/bin/bash

clear

set -e
echo "=== Initial setup script ==="
echo "This script requires sudo access."
sudo -v

# Install Ansible
if ! command -v ansible &> /dev/null; then
    echo "Installing Ansible"
    if [ "$(uname)" = "Darwin" ]; then
        if ! command -v brew &> /dev/null; then
            echo "Installing Homebrew"
            xcode-select --install 
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install ansible
    elif [ -f /etc/os-release ] && grep -q "Ubuntu" /etc/os-release; then
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository --yes --update ppa:ansible/ansible
        sudo apt install -y ansible
        sudo apt autoremove -y
    else
        echo "Unsupported OS"
        exit 1
    fi
else
    echo "Ansible is already installed"
fi

REPO="https://github.com/eli-s/my-setup.git"

ansible-pull -U "$REPO" -i localhost, main.yml --ask-become-pass
