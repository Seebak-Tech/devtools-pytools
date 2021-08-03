#!/bin/bash
echo admin1 | sudo -S service ssh restart
echo admin1 | sudo chmod o+w /var/run/docker.sock
sed -i '/DISPLAY/s/=:0/='$DISPLAY'/g' /home/admin/.zshrc
tmux new -s default -d
exec "$@"
