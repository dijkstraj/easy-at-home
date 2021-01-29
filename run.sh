#!/bin/bash

if [ -e /tmp/easy-at-home ]; then
  rm -rf /tmp/easy-at-home
fi
git clone https://github.com/dijkstraj/easy-at-home.git /tmp/easy-at-home
sudo apt update && sudo apt install -y ansible
ansible-playbook /tmp/easy-at-home/main.yml --extra-vars "user=${USER} email=${EMAIL}"
