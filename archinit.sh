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

# Upgrading system
sed -e 's!#(Color)!\1!' /etc/pacman.conf 
pacman -Sy --noconfirm reflector sudo vim 
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bkup && reflector --verbose -l 10 -p http --sort rate --save /etc/pacman.d/mirrorlist
pacman -Rs --noconfirm reflector
pacman -Syu --noconfirm 

#Add user
useradd -m -g users -u 785 $USERNAME
echo "$USERNAME ALL=(ALL) ALL" >> /etc/sudoers

#secure ssh
printf "PermitRootLogin no\nPort 23146\n" >> /etc/ssh/sshd_config
systemctl restart sshd

#Set passwords
printf "\n *** Root Password *** \n"
passwd
printf "\n *** $USERNAME Password *** \n"
passwd $USERNAME


# Configuring user: deployer
useradd -m -g users -G wheel -s /bin/bash deployer
passwd deployer <<EOF
$USERPASS
$USERPASS
EOF
chown -R deployer:users /home/deployer
su - deployer -c &quot;ssh-keygen -t rsa -f ~/.ssh/id_rsa -N $USERPASS&quot;
su - deployer -c 'curl &quot;https://raw.github.com/asayers/provision/master/bashrc&quot; > ~/.bashrc'

# Setting up git
su - deployer -c &quot;git config --global user.name '$GITNAME'&quot;
su - deployer -c &quot;git config --global user.email '$GITEMAIL'&quot;

# Setting up ruby
su deployer
cd ~
curl https://raw.github.com/fesplugas/rbenv-installer/master/bin/rbenv-installer | bash
rbenv install 1.9.3-p194
rbenv global 1.9.3-p194
rbenv bootstrap
rbenv rehash
exit

# Setting up nginx
mkdir /etc/nginx/sites-available
mkdir /etc/nginx/sites-enabled
curl &quot;https://raw.github.com/asayers/provision/master/nginx.conf&quot; > /etc/nginx/nginx.conf
curl &quot;https://raw.github.com/asayers/provision/master/nginx_default.conf&quot; > /etc/nginx/sites-available/default
systemctl enable nginx
systemctl start nginx

# Setting up postgres
chown -R postgres /var/lib/postgres/
su - postgres -c &quot;initdb --locale en_US.UTF-8 -D '/var/lib/postgres/data'&quot;
su - postgres -c &quot;createuser -d deployer&quot;
mkdir /run/postgresql
chown postgres /run/postgresql/
systemctl enable postgresql
systemctl start postgresql

# Setting up redis
systemctl enable redis
systemctl start redis

# Maybe add a password for the deployer postgres user? Use -P <<EOF etc.
