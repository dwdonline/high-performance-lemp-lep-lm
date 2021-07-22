#!/bin/bash
#### Installation script to setup MariaDB for WordPress High Performance
#### By Philip N. Deatherage, Deatherage Web Development
#### www.dwdonline.com

pause(){
    read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}

echo "---> WELCOME! FIRST WE NEED TO MAKE SURE THE SYSTEM IS UP TO DATE!"

read -p "Would you like to install updates now? <y/N> " choice
case "$choice" in 
  y|Y|Yes|yes|YES ) 
apt update
apt -y upgrade
;;
  n|N|No|no|NO )
echo "Ok, we won't update the system first. This may cause issues if you have a really old system."
;;
  * ) echo "invalid";;
esac

echo "---> Now, we'll install build-essentials and zip/unzip."
pause

apt update
apt -y install build-essential zip unzip

echo "All done with the system basics."

echo "---> Let's add a new admin user and block the default root from logging in:"
pause

read -e -p "---> What would you like your new admin user to be?: " NEW_ADMIN
read -e -p "---> What should the new admin password be?: " NEW_ADMIN_PASSWORD
read -e -p "---> What should we make the SSH port?: " -i "22" NEW_SSH_PORT
read -e -p "---> Enter your web user usually www-data (nginx for Ubuntu): " -i "www-data" MY_WEB_USER

adduser ${NEW_ADMIN} --disabled-password --gecos ""
echo "${NEW_ADMIN}:${NEW_ADMIN_PASSWORD}"|chpasswd

gpasswd -a ${NEW_ADMIN} sudo

sudo usermod -aG ${MY_WEB_USER} ${NEW_ADMIN}

sed -i "s,PermitRootLogin yes,PermitRootLogin no,g" /etc/ssh/sshd_config

sed -i "s,Port 22,Port ${NEW_SSH_PORT},g" /etc/ssh/sshd_config

service ssh restart

echo "---> ALRIGHT, NOW WE ARE READY TO INSTALL THE GOOD STUFF!"
pause

echo "---> LET'S INSTALL MARIADB"
pause

echo
read -e -p "---> What do you want your MySQL root password to be?: " MYSQL_ROOT_PASSWORD
# read -e -p "---> What version of Ubuntu? 14 is trusty, 15 is wily, 16 is xenial: " -i "xenial" UBUNTU_VERSION

cd 

wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup

echo "32e01fbe65b4cecc074e19f04c719d1a600e314236c3bb40d91e555b7a2abbfc mariadb_repo_setup" \
    | sha256sum -c -

chmod +x mariadb_repo_setup

sudo ./mariadb_repo_setup \
   --mariadb-server-version="mariadb-10.5"

sudo apt update y

export DEBIAN_FRONTEND=noninteractive
echo "mariadb-server-10.5 mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}" | sudo debconf-set-selections
echo "mariadb-server-10.5 mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}" | sudo debconf-set-selections

sudo apt install mariadb-server mariadb-backup -y

service mysql restart

/usr/bin/mysql_secure_installation

cd

echo "---> OK, WE ARE DONE SETTING UP THE SERVER. LET'S PROCEED TO CONFIGURING DATABASE."
pause


read -p "Would you like to install the WordPress Database now? <y/N> " choice
case "$choice" in
  y|Y|Yes|yes|YES )
echo
read -e -p "---> What do you want to name your WordPress MySQL database?: " WP_MYSQL_DATABASE
read -e -p "---> What do you want to name your WordPress MySQL user?: " WP_MYSQL_USER
read -e -p "---> What do you want your WordPress MySQL password to be?: " WP_MYSQL_USER_PASSWORD

echo "Please enter your MySQL root password below, which is  ${MYSQL_ROOT_PASSWORD}:"

mysql -u root -p -e "CREATE database ${WP_MYSQL_DATABASE}; CREATE user '${WP_MYSQL_USER}'@'localhost' IDENTIFIED BY '${WP_MYSQL_USER_PASSWORD}'; GRANT ALL PRIVILEGES ON ${WP_MYSQL_DATABASE}.* TO '${WP_MYSQL_USER}'@'localhost' IDENTIFIED BY '${WP_MYSQL_USER_PASSWORD}';"

echo "Your database name is: ${WP_MYSQL_DATABASE}"
echo "Your database user is: ${WP_MYSQL_USER}"
echo "Your databse password is: ${WP_MYSQL_USER_PASSWORD}"

service mysql restart

;;
  n|N|No|no|NO )
echo "Ok, we won't install the DB - you are on your own."
;;
  * ) echo "invalid";;
esac

echo "I just saved you a shitload of time and headache. You're welcome."
{"mode":"full","isActive":false}
