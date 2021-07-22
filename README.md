The two scripts here will setup a Ubuntu 20 server for high performance WordPress/WooCommerce hosting with Ubuntu, Nginx, PHP and a second server with MariaDB.

To use, login to your server and run the following: cd to the directory you want to put the script in. I usually just go to root:

For the DB server (setup first)
cd

wget -q https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/mariadb_install.sh

chmod 550 mariadb_install.sh

./mariadb_install.sh


For the WebServer
cd

wget -q https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/lep_install.sh

chmod 550 lep_install.sh

./lep_install.sh
