#!/bin/bash

if [ -e /tmp/easy-at-home ]; then
  rm -rf /tmp/easy-at-home
fi
git clone https://github.com/dijkstraj/easy-at-home.git /tmp/easy-at-home
/tmp/easy-at-home/init.sh "$EMAIL"
