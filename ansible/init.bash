#!/usr/bin/env bash
set -euo pipefail

if ! grep -q "ubuntu" /etc/os-release; then
    echo "You're running a distro that doesn't seem to be derived from Ubuntu. This script will not work as it relies heavily on apt and Ubuntu paths."
    exit
fi
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if ! hash ansible-playbook 2> /dev/null
then
    sudo apt update
    sudo apt install -y software-properties-common
    sudo apt-add-repository --yes --update ppa:ansible/ansible
    sudo apt install -y ansible
fi

sudo ansible-galaxy collection install -i -r "$DIR/requirements.yml" &> /dev/null
sudo ansible-galaxy install -i -r "$DIR/requirements.yml" &> /dev/null

sudo ansible-playbook "$DIR/workspace.yml" -vvv
