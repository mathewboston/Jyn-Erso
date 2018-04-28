#!/bin/bash

gitdir=/home/admin/admin.git
curdir=$(pwd)

sudo apt update
sudo apt upgrade -y

#set up php
if [[ -z $(which php) ]]; then
	echo "No php found, Installing php-common..."
	sudo apt install php-common -y
fi

#set up php cli
if [[ -z $(php -v | grep cli) ]]; then
	echo "No Cli found, Installing php-cli"
	sudo apt install php-cli -y
fi

#set up php fpm
if [[ -z $(sudo find / -name php*-fpm) ]]; then
	echo "No Fpm found, Installing php-fpm"
	sudo apt install php-fpm -y
fi
sudo service php7.0-fpm stop

#set up webserver
if [[ -z $(which nginx) ]]; then
	echo "No nginx webserver found, Installing nginx..."
	sudo apt install nginx -y
fi

#set up ssh server
if [[ -z $(which sshd) ]]; then
	echo "Installing ssh server..."
	sudo apt install openssh-server -y
fi

#check if git server is present
if [[ -z $(which git) ]]; then
	echo "Git server not intalled, installing..."
	sudo apt install git-core -y
fi

#check if openssl is present
if [[ -z $(which openssl) ]]; then
	echo "Installing openssl..."
	sudo apt install openssl -y
fi

#check if admin user is present
if [[ -z $(cat /etc/passwd | cut -b -5 | grep admin) ]]; then
	echo "Adding admin user..."
	sudo useradd -N admin
	echo -e "empiredidnothingwrong\nempiredidnothingwrong\n" | sudo passwd admin
fi

#set up webserver ssl
sudo mkdir -p /etc/ssl/certs
sudo mkdir -p /etc/ssl/private
sudo chmod u+rwx $_
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/private.key -out /etc/ssl/certs/certificate.crt -subj "/C=US/ST=Maryland/L=./O=./OU=./CN=Mathew Boston"
sudo openssl dhparam -out /etc/ssl/certs/dh.pem 2048

#setting up webserver
#check for ip to use
IFS=' '
read -ra IPARRAY <<< $(hostname -I)
if [[ -z "${IPARRAY[1]}" ]]; then
	curip="${IPARRAY[0]}"
else
	echo "More than one IP"
	loop=true
	while [[ $loop == true ]]; do
		for ip in "${IPARRAY[@]}"; do
			echo "Use $ip? [Yn]"
			read bool
			if [[ $bool == "Y" || $bool == "y" || $bool == "Yes" || $bool == "yes" ]]; then
				curip=$ip
				loop=false
				break
			fi	
		done
	done
fi

#setup config ip
cat $curdir/default | sed "s/server_name 127.0.0.1/server_name $curip/" > temp
sudo mv temp /etc/nginx/sites-enabled/echo
sudo mkdir -p /var/www/echo
sudo cp $curdir/index.php $_/index.php

#setup php
sudo cp $curdir/php.ini /etc/php/7.0/fpm/php.ini
sudo service php7.0-fpm start

#setting up git bare repository
echo "Setting up git..."
sudo git config --global user.email "admin@example.com"
sudo git config --global user.name "admin"

sudo mkdir -p $gitdir
cd $_
sudo git init --bare
#make a temp repository to add files to the server
cd $curdir
mkdir -p git/admin
cd $_
sudo git init
mkdir setup
cp $curdir/Promt2Setup.sh setup/
cp $curdir/default setup/
cp $curdir/Watchdog.sh .
cp $curdir/README .
sudo git add .
sudo git commit -m "filling respository" -a
sudo git remote add origin $gitdir
sudo git push origin master
cd $curdir
sudo rm -dr git/

#so watchdog can see new files added to the repository
cd /home/admin
sudo git clone admin.git
#check if admin user is present
if [[ -z $(cat /etc/group | cut -b -8 | grep gitUsers) ]]; then
	echo "Adding gitUsers group..."
	sudo groupadd gitUsers
fi
sudo usermod -a -G gitUsers admin
sudo usermod -a -G gitUsers www-data

#give admin user ownership of files
sudo chown -R admin:gitUsers /home/admin
sudo chown -R admin:gitUsers /var/www/echo
sudo chmod -R ug+rwx /home/admin/admin #allows website to modify website

#set nginx, git, and ssh server to autostart
sudo systemctl enable ssh.socket
sudo systemctl enable nginx.service
sudo systemctl restart nginx.service
#sudo service nginx restart

echo "Setup Complete..."
