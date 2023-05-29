#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

echo "####################"
echo "getting latest defaults"
echo "####################"


apt update
apt upgrade -y


echo "####################"
echo "installing conveniences"
echo "####################"
apt install ripgrep vim fzf net-tools git unattended-upgrades tmux containerd -y


echo "####################"
echo "generating host name"
echo "####################"

CURRENT_HOSTNAME=$(hostname)
ETC_HOSTNAME=$(cat /etc/hostname)

if [ "$CURRENT_HOSTNAME" = "$ETC_HOSTNAME" ] && [ "$CURRENT_HOSTNAME" != "ubuntu" ]; then
    echo "##### keeping hostname: $CURRENT_HOSTNAME"
else
    echo "##### detected default hostname, changing."
    pwd
    cd gen-hostname || (git clone https://github.com/gdoteof/gen-hostname.git && cd gen-hostname)
    NEW_HOSTNAME=$(./get_hostname.sh)
    cd ..
    echo "changing hostname FROM: ->>$CURRENT_HOSTNAME<<-"
    echo "changing /etc/hostname FROM: ->>$ETC_HOSTNAME<<-"
    CURRENT_HOSTNAME=$NEW_HOSTNAME
    ETC_HOSTNAME=$NEW_HOSTNAME
    echo "changing hostname TO: ->>$CURRENT_HOSTNAME<<-"
    hostname=$NEW_HOSTNAME
    echo "changing /etc/hostname TO: ->>$ETC_HOSTNAME<<-"
    echo $NEW_HOSTNAME > /etc/hostname
fi
