#!/bin/bash

clear

set -e
echo "=== Initial setup script ==="

# check if user is not root
if [ "$(whoami)" != "root"] then
    # exit if sudo is not available or user is not root
    if ! command -v sudo &> /dev/null; then
       echo "sudo is not available. Exiting."
       exit 1
    fi
    sudo -v
fi

# Install Ansible
if ! command -v ansible &> /dev/null; then
    echo "Installing Ansible"
    if [ "$(uname)" = "Darwin" ]; then
        if ! command -v brew &> /dev/null; then
            echo "Installing Homebrew"
            xcode-select --install 2>/dev/null || true
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install ansible age sops
    elif [ -f /etc/os-release ] && grep -q "Ubuntu" /etc/os-release; then
        sudo apt install -y software-properties-common
        sudo add-apt-repository --yes --update ppa:ansible/ansible
        sudo apt update
        sudo apt install -y ansible age
        sudo apt autoremove -y

        if ! command -v curl &> /dev/null; then
            sudo apt install -y curl
        fi

        SOPS_VERSION="${$(curl -sL -o /dev/null -w "%{url_effective}" "https://github.com/getsops/sops/releases/latest")##*/tag/}"

        # Install SOPS
        curl -LO "https://github.com/getsops/sops/releases/download/$SOPS_VERSION/sops-$SOPS_VERSION.linux.amd64"
        mv sops-v3.11.0.linux.amd64 /usr/local/bin/sops
        sudo chmod +x /usr/local/bin/sops
    else
        echo "Unsupported OS"
        exit 1
    fi
else
    echo "Ansible is already installed"
fi

REPO="https://github.com/eli-s/my-setup.git"

ansible-pull -U "$REPO" -i localhost, main.yml --ask-become-pass
