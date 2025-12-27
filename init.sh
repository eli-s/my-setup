#!/bin/bash

clear

set -e
echo "=== Initial setup script ==="

if [ $EUID -eq 0 ]; then
    SUDO=""
    echo "Running as root"
elif command -v sudo &> /dev/null; then
    SUDO="sudo"
    echo "Using sudo"
    sudo -v
else
    echo "No privileges to run this script, and sudo is not available. Exiting."
    exit 1
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
        $SUDO apt install -y software-properties-common
        $SUDO add-apt-repository --yes --update ppa:ansible/ansible
        $SUDO apt update
        $SUDO apt install -y git ansible age
        $SUDO apt autoremove -y

        if ! command -v curl &> /dev/null; then
            $SUDO apt install -y curl
        fi

        LATEST_URL=$(curl -sL -o /dev/null -w "%{url_effective}" "https://github.com/getsops/sops/releases/latest")
        SOPS_VERSION="${LATEST_URL##*/tag/}"

        # Install SOPS
        curl -LO "https://github.com/getsops/sops/releases/download/$SOPS_VERSION/sops-$SOPS_VERSION.linux.amd64"
        mv "sops-$SOPS_VERSION.linux.amd64" /usr/local/bin/sops
        $SUDO chmod +x /usr/local/bin/sops
    else
        echo "Unsupported OS" 
        exit 1
    fi
else
    echo "Ansible is already installed"
fi

REPO="https://github.com/eli-s/my-setup.git"

# Only ask for become password if not root and sudo requires password
if [[ $EUID -eq 0 ]]; then
    ansible-pull -U "$REPO" main.yml -v
elif sudo -n true 2>/dev/null; then
    # Passwordless sudo works
    ansible-pull -U "$REPO" main.yml -v
else
    # Need to ask for password
    ansible-pull -U "$REPO" main.yml -v --ask-become-pass
fi

zsh
