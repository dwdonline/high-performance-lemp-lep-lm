#!/bin/bash
#### Installation script to setup Ubuntu, Nginx,  Php-fpm, and Wordpress settings
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

echo "---> INSTALLING NGINX AND PHP-FPM"

# add-apt-repository -y ppa:ondrej/php
#
# apt -y update
#
# apt -y install php-pear php-curl php7.1-fpm php7.1-mcrypt php7.1-curl php7.1-cli php7.1-mysql php7.1-gd php7.1-intl php7.1-xsl php7.1-gd php-ssh2 php7.1-mbstring php7.1-soap php7.1-zip libgeoip-dev libgd-dev libssh2-1 libzip4 libperl-dev libpcre3 libpcre3-dev libssl-dev zlib1g-dev uuid-dev nginx
#
# apt -y install php5.6-fpm php5.6-mcrypt php5.6-curl php5.6-cli php5.6-mysql php5.6-gd php5.6-intl php5.6-xsl php5.6-gd php-ssh2 php5.6-mbstring php5.6-soap php5.6-zip

sudo apt -y install nginx

sudo apt -y install php-fpm php-pear php-curl php-mcrypt php-curl php-cli php-mysql php-gd php-intl php-intl php-xsl php-ssh2 php-xml php-xmlrpc php-mbstring php-soap php-zip libgeoip-dev libgd-dev libssh2-1 libzip4 libperl-dev libssl-dev nginx 

echo "---> NOW, LET'S COMPILE NGINX WITH PAGESPEED"
pause

# apt autoremove nginx* -y
#
# apt install libxslt-dev gcc -y

cd 

mkdir nginx_install

read -p "---> What version of Pagespeed do you want to use?: " -i "1.14.36.1-stable" NPS_VERSION

cd $HOME/nginx_install

wget https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}.zip
unzip v${NPS_VERSION}.zip

cd incubator-pagespeed-ngx-${NPS_VERSION}/

psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
wget ${psol_url}
tar -xzvf $(basename ${psol_url})  # extracts to psol/

cd $HOME/nginx_install
wget https://github.com/arut/nginx-dav-ext-module/archive/master.zip
unzip master.zip
rm master.zip

cd $HOME/nginx_install
wget https://github.com/openresty/echo-nginx-module/archive/master.zip
unzip master.zip
rm master.zip

cd $HOME/nginx_install
wget https://github.com/itoffshore/nginx-upstream-fair/archive/master.zip
unzip master.zip
rm master.zip

cd $HOME/nginx_install
wget https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/master.zip
unzip master.zip
rm master.zip

cd $HOME/nginx_install
wget -q http://nginx.org/download/nginx-1.20.1.tar.gz
tar -xzvf nginx-1.13.12.tar.gz
cd nginx-1.20.1

# PS_NGX_EXTRA_FLAGS="--with-cc=/usr/bin/gcc --with-ld-opt=-static-libstdc++"
PS_NGX_EXTRA_FLAGS="--with-cc=/usr/lib/gcc-mozilla/bin/gcc  --with-ld-opt=-static-libstdc++"

./configure --user=www-data --group=www-data --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now' --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --modules-path=/usr/lib/nginx/modules --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-pcre-jit --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-http_auth_request_module --with-http_v2_module --with-http_dav_module --with-http_slice_module --with-threads --with-http_addition_module --with-http_geoip_module=dynamic --with-http_gunzip_module --with-http_gzip_static_module --with-http_image_filter_module=dynamic --with-http_sub_module --with-http_xslt_module=dynamic --with-stream=dynamic --with-stream_ssl_module --with-mail=dynamic --with-mail_ssl_module --add-module=$HOME/nginx_install/nginx-dav-ext-module-master --add-module=$HOME/nginx_install/echo-nginx-module-master --add-module=$HOME/nginx_install/nginx-upstream-fair-master --add-module=$HOME/nginx_install/ngx_http_substitutions_filter_module-master --add-module=$HOME/nginx_install/incubator-pagespeed-ngx-${NPS_VERSION} ${PS_NGX_EXTRA_FLAGS}

# make
#
# make install
#
# service nginx restart

make modules

cp objs/ngx_pagespeed.so /usr/share/nginx/modules/

#create directory for the cache
mkdir -p /var/ngx_pagespeed_cache

echo "Don't worry, that message is normal. We'll unmask and restart it."

sudo systemctl unmask nginx.service

service nginx restart

echo "---> INSTALLING MySQL tools."
pause

wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup

echo "32e01fbe65b4cecc074e19f04c719d1a600e314236c3bb40d91e555b7a2abbfc mariadb_repo_setup" \
    | sha256sum -c -

chmod +x mariadb_repo_setup

sudo ./mariadb_repo_setup \
   --mariadb-server-version="mariadb-10.5"

sudo apt update -y

sudo apt install -y mariadb-client mysqldump mysqlreport mysqlcheck mariadb-backup
cd

echo "---> OK, WE ARE DONE SETTING UP THE SERVER. LET'S PROCEED TO CONFIGURING THE NGINX HOST FILES."
php -v

pause

    read -p "---> What will your main domain be - ie: domain.com: " MY_DOMAIN
    read -p "---> Any additional domain name(s) or sub domains, seperated by a space: domain.com dev.domain.com: " -i "www.${MY_DOMAIN}" MY_EXTRA_DOMAINS
    read -p "---> Enter your web root path: " -i "/var/www/${MY_DOMAIN}/public" MY_SITE_PATH   
    read -p "---> Which version of php will you be using? LIKELY 8 OR 8.1: " -i "8" PHP_VERSION   
    
    #Create host root
    cd
    mkdir -p ${MY_SITE_PATH}
    
    mkdir -p /etc/nginx/conf.d
    
    cd /etc/nginx/conf.d

    wget -qO  /etc/nginx/conf.d/pagespeed.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/conf.d/pagespeed.conf
    wget -qO  /etc/nginx/conf.d/fastcgi-params.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/conf.d/fastcgi-params.conf
    wget -qO  /etc/nginx/conf.d/headers.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/conf.d/headers.conf
    wget -qO  /etc/nginx/conf.d/gzip.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/conf.d/gzip.conf
    wget -qO  /etc/nginx/conf.d/http.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/conf.d/http.conf
    wget -qO  /etc/nginx/conf.d/limits.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/conf.d/limits.conf
    wget -qO  /etc/nginx/conf.d/mime_types.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/conf.d/mime_types.conf
    wget -qO  /etc/nginx/conf.d/security.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/conf.d/security.conf
    wget -qO  /etc/nginx/conf.d/ssl.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/conf.d/ssl.conf
    wget -qO  /etc/nginx/conf.d/static-files.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/conf.d/static-files.conf
    
    cd /etc/nginx
    
    mv nginx.conf nginx.conf.bak
    wget -qO  /etc/nginx/nginx.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/nginx.conf

    mkdir -p /etc/nginx/sites-enabled

    rm -rf /etc/nginx/sites-available/default

    mkdir -p /etc/nginx/sites-available
    
    cd /etc/nginx/sites-available
    
    rm -rf /etc/nginx/sites-enabled/default
    
    wget -q https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/sites-available/default.conf

# read -p "Will you be running Magento 1 (Answer m1), Magento 2 (Answer m2), or WordPress? (Answer WP). <y/N> " choice
# case "$choice" in
#   y|Y|Yes|yes|YES|1|M1|m1 )
#     wget -qO /etc/nginx/sites-available/${MY_DOMAIN}.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/sites-available/magento.conf
# ;;
#   n|N|No|no|NO|2|M2|m1 )
#     wget -qO /etc/nginx/sites-available/${MY_DOMAIN}.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/sites-available/magento2.conf
# ;;
#   WP|wp|3|Wp|wP|WordPress )
	echo "---> OK, WE ARE DONE CONFIGURING THE NGINX HOST FILES. NOW, LET'S CREATE THE WEBSITE HOST FILES FOR WORDPRESS."
    wget -qO /etc/nginx/sites-available/${MY_DOMAIN}.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/sites-available/wp.conf
# ;;
#   * ) echo "invalid choice";;
# esac

    sed -i "s/example.com/${MY_DOMAIN}/g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s/www.example.com/www.${MY_DOMAIN} ${MY_EXTRA_DOMAINS}/g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,root /var/www/html,root ${MY_SITE_PATH},g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,user  www-data,user  ${MY_WEB_USER},g" /etc/nginx/nginx.conf
    sed -i "s,access_log,access_log /var/log/nginx/${MY_DOMAIN}_access.log;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,error_log,error_log /var/log/nginx/${MY_DOMAIN}_error.log;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf

    sed -i "s,fastcgi_pass,fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf

    ln -s /etc/nginx/sites-available/${MY_DOMAIN}.conf /etc/nginx/sites-enabled/${MY_DOMAIN}.conf
    ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

read -p "Would you like to setup the host files for WordPress? <y/N> " choice
case "$choice" in 
  y|Y|Yes|yes|YES ) 

    cd /etc/nginx
    mkdir -p wordpress
    cd wordpress
    
    wget -qO  /etc/nginx/wordpress/yoast.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/wordpress/yoast.conf
    wget -qO  /etc/nginx/wordpress/wordfence.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/wordpress/wordfence.conf    
;;
  n|N|No|no|NO )
    echo "You just skipped installing WordPress host files."
;;
  * ) echo "invalid choice";;
esac


read -p "Would you like to would you like to install the settings for RankMath for WordPress? <y/N> " choice
case "$choice" in 
  y|Y|Yes|yes|YES ) 

    cd /etc/nginx
    cd wordpress
    
    wget -qO  /etc/nginx/wordpress/rankmath.conf https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/nginx/wordpress/rankmath.conf
    
    cd /etc/nginx
        
    sed -i "s,#	include wordpress/rankmath.conf;,	include wordpress/rankmath.conf;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    
;;
  n|N|No|no|NO )
    echo "You just skipped installing WordPress rankmath files."
;;
  * ) echo "invalid choice";;
esac

# service nginx restart
sudo systemctl reload nginx

service php${PHP_VERSION}-fpm restart

echo "---> NOW, LET'S SETUP SSL."
pause

read -p "Do you want to use Let's Encrypt? <y/N> " choice
case "$choice" in 
  y|Y|Yes|yes|YES ) 
#cd /etc/ssl/

cd

sudo apt install certbot python3-certbot-nginx -y

read -p "---> Any additional domain name(s) seperated: domain.com,dev.domain.com (no spaces): " -i "-d www.${MY_DOMAIN}" OTHER_DOMAINS

#export DOMAINS="${MY_DOMAIN},${MY_DOMAINS}"
#export DIR="${MY_SITE_PATH}"

# sudo certbot certonly --webroot --webroot-path=${MY_SITE_PATH} -d ${MY_DOMAIN} ${OTHER_DOMAINS}

sudo certbot --nginx -d ${MY_DOMAIN} ${OTHER_DOMAINS}

# openssl dhparam -out /etc/ssl/dhparams.pem 2048

MY_SSL="/etc/letsencrypt/live/${MY_DOMAIN}/fullchain.pem"
MY_SSL_KEY="/etc/letsencrypt/live/${MY_DOMAIN}/privkey.pem"

# echo "---> NOW, LET'S SETUP SSL to renew by checking each day and renewing any that have less than 30 days left."
# pause
#
# #Add cronjob for renewing ssl
# #(crontab -l 2>/dev/null; echo "@daily /renewCerts.sh") | crontab -
# (crontab -l 2>/dev/null; echo '15 3 * * * /usr/bin/certbot renew --quiet --renew-hook "/bin/systemctl reload nginx"') | crontab -
# ;;
#   n|N|No|no|NO )
#
# echo "OK, we will install a self-signed SSL then."
#
# echo
# read -p "---> What is the 2 letter country? - ie: US: " -i "US" MY_COUNTRY
# read -p "---> What is your state/province? - ie: California: " -i "California" MY_REGION
# read -p "---> What is your city? - ie: Los Angeles: " -i "Los Angeles" MY_CITY
# read -p "---> What is your company - ie: Deatherage Co: " -i "" MY_O
# read -p "---> What is your departyment - ie: IT (Can be blank): " -i "" MY_OU
#
# mkdir -p /etc/ssl/sites/
#
# sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/sites/${MY_DOMAIN}_selfsigned.key -out /etc/ssl/sites/${MY_DOMAIN}_selfsigned.crt -subj "/C=${MY_COUNTRY}/ST=${MY_REGION}/L=${MY_CITY}/O=${MY_O}/OU=${MY_OU}/CN=${MY_DOMAIN}"
#
# MY_SSL="/etc/ssl/sites/${MY_DOMAIN}_selfsigned.crt"
# MY_SSL_KEY="/etc/ssl/sites/${MY_DOMAIN}_selfsigned.key"
#
# openssl dhparam -out /etc/ssl/dhparams.pem 2048
#
# ;;
#   * ) echo "invalid";;
# esac

    sed -i "s,listen 80;,listen 443 ssl http2;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,#listen80,listen  80;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,#servername,server_name  ${MY_DOMAIN} www.${MY_DOMAIN};,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,#return,return 301 https://www.${MY_DOMAIN}$request_uri;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,#ssl_certificate_name,ssl_certificate  ${MY_SSL};,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,#ssl_certificate_key,ssl_certificate_key ${MY_SSL_KEY};,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,#include conf.d/ssl.conf,include conf.d/ssl.conf,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf

service nginx restart

#Move to site root
cd ${MY_SITE_PATH}

read -p "Would you like to install Adminer for managing your MySQL databases now? <y/N> " choice
case "$choice" in 
  y|Y|Yes|yes|YES ) 
    wget -q https://www.adminer.org/static/download/4.8.1/adminer-4.8.1-mysql.php
    mv adminer-4.8.1-mysql.php adminer.php
;;
  n|N|No|no|NO )
    echo "You chose not to install Adminer."
;;
  * ) echo "invalid choice";;
esac

# echo "---> Let's remove sendmail and install Postfix to handle sending mail:"
echo "---> Let's remove sendmail:"
pause

apt --purge remove sendmail sendmail-base sendmail-bin

read -p "---> What would you like your host to be? I like it to be something like sendmail.domain.com: " -i "sendmail.${MY_DOMAIN}" POSTFIX_SERVER

debconf-set-selections <<< "postfix postfix/mailname string ${POSTFIX_SERVER}"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt install -y postfix

read -p "Would you like to install WordPress now? <y/N> " choice
case "$choice" in
  y|Y|Yes|yes|YES )
echo
read -p "---> What do you want to name your WordPress MySQL database?: " WP_MYSQL_DATABASE
read -p "---> What do you want to name your WordPress MySQL user?: " WP_MYSQL_USER
read -p "---> What do you want your WordPress MySQL password to be?: " WP_MYSQL_USER_PASSWORD
read -p "---> What do you want your WordPress directory to be. If this will be at the root enter the same as your root ${MY_SITE_PATH} or if it will be for Magento wp:" -i "${MY_SITE_PATH}/wp" WP_DIRECTORY

cd "${MY_SITE_PATH}"

mkdir -p ${WP_DIRECTORY}

cd "${WP_DIRECTORY}"

MY_WP_SITE_PATH="${WP_DIRECTORY}"

wget -q https://wordpress.org/latest.zip

unzip latest.zip

cd wordpress

mv * ../

echo "Please enter your MySQL root password below:"

mysql -u root -p -e "CREATE database ${WP_MYSQL_DATABASE}; CREATE user '${WP_MYSQL_USER}'@'localhost' IDENTIFIED BY '${WP_MYSQL_USER_PASSWORD}'; GRANT ALL PRIVILEGES ON ${WP_MYSQL_DATABASE}.* TO '${WP_MYSQL_USER}'@'localhost' IDENTIFIED BY '${WP_MYSQL_USER_PASSWORD}';"

echo "Your database name is: ${WP_MYSQL_DATABASE}"
echo "Your database user is: ${WP_MYSQL_USER}"
echo "Your databse password is: ${WP_MYSQL_USER_PASSWORD}"

service mysql restart

cd "${MY_WP_SITE_PATH}"

cp -r wp-config-sample.php wp-config.php

sed -i "s,database_name_here,${WP_MYSQL_DATABASE},g" wp-config.php
sed -i "s,username_here,${WP_MYSQL_USER},g" wp-config.php
sed -i "s,password_here,${WP_MYSQL_USER_PASSWORD},g" wp-config.php


#set WP salts
perl -i -pe'
  BEGIN {
    @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
    push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
    sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
  }
  s/put your unique phrase here/salt()/ge
' wp-config.php

;;
  n|N|No|no|NO )
    echo "You didn\'t install WordPress."
    service mysql restart
;;
  * ) echo "invalid choice";;
esac

echo "---> Let's add a robots.txt file:"
wget -qO ${MY_SITE_PATH}/robots.txt https://raw.githubusercontent.com/dwdonline/high-performance-lemp-lep-lm/master/robots.txt
sed -i "s,Sitemap: http://YOUR-DOMAIN.com/sitemap_index.xml,Sitemap: https://www.${MY_DOMAIN}/sitemap_index.xml,g" ${MY_SITE_PATH}/robots.txt

echo "---> Let's set the permissions for the site:"
pause

echo "Lovely, this may take a few minutes. Dont fret."

cd "${MY_SITE_PATH}"

chown -R ${NEW_ADMIN}.www-data ${MY_SITE_PATH}

chown -R ${NEW_ADMIN}.www-data /var/www

chown -R ${NEW_ADMIN}.www-data robots.txt

cd ${WP_DIRECTORY}
find ${WP_DIRECTORY}/wp-content/ -type f -exec chmod 600 {} \;
find ${WP_DIRECTORY}/wp-content/ -type d -exec chmod 700 {} \;
chmod 700 wp-includes
chmod 600 wp-config.php

chown -R www-data.www-data wp-content

sudo chmod -R 775 ${MY_SITE_PATH}

echo "---> Let's cleanup:"
pause
cd
rm -rf nginx_install

cd ${MY_SITE_PATH}

rm -rf wordpress latest.zip

apt-mark hold nginx*

cd /etc/nginx/sites-enabled

rm -rf /etc/nginx/sites-enabled/default

cd

# Let's set the server to update itself:
#sudo dpkg-reconfigure --priority=low unattended-upgrades

echo "I just saved you a shitload of time and headache. You're welcome."
{"mode":"full","isActive":false}
