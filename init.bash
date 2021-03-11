#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
sudo apt install -y ansible
sudo ansible-galaxy collection install -r $DIR/requirements.yml
sudo ansible-galaxy install -r $DIR/requirements.yml
sudo ansible-playbook $DIR/local.yml
