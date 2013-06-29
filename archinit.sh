#!/bin/bash

read -p "Username: " USERNAME
read -p "UID: " USERID


# Setting locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo 'LANG="en_US.UTF-8"' > /etc/locale.conf
echo "KEYMAP=US" > /etc/vconsole.conf
locale-gen

# Setting timezone to London
ln -s /usr/share/zoneinfo/America/New_York /etc/localtime   # Already set to UTC

# Upgrade pacman
sed -e 's!#(Color)!\1!' /etc/pacman.conf 
pacman -Sy --noconfirm reflector sudo vim 
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bkup && reflector --verbose -l 10 -p http --sort rate --save /etc/pacman.d/mirrorlist
pacman -Rs --noconfirm reflector

# Upgrade system
pacman -Syu --noconfirm --ignore filesystem,bash
pacman -S --noconfirm bash
pacman -Su --noconfirm 

#Add user
useradd -m -g users -u $USERID $USERNAME
echo "$USERNAME ALL=(ALL) ALL" >> /etc/sudoers

#secure ssh
printf "PermitRootLogin no\nPort 23146\n" >> /etc/ssh/sshd_config
systemctl restart sshd

#Set passwords
printf "\n *** Root Password *** \n"
passwd
printf "\n *** $USERNAME Password *** \n"
passwd $USERNAME


