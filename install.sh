#!/bin/bash

# Based on https://peteris.rocks/blog/unattended-installation-of-wordpress-on-ubuntu-server/
# Variables
WP_DOMAIN="wordpress.rdf.loc"
WP_ADMIN_USERNAME="admin"
WP_ADMIN_PASSWORD="admin"
WP_ADMIN_EMAIL="no@spam.org"
WP_DB_NAME="wordpress"
WP_DB_USERNAME="wordpress"
WP_DB_PASSWORD="wordpress"
WP_PATH="/var/www/html/wordpress"
MYSQL_ROOT_PASSWORD="root"

# Install software
# We are going to install nginx, PHP and MySQL.
# By default, mysql-server is going to ask for the root password and we automate that with debconf-set-selections.
echo "Install software"
echo "mysql-server-5.7 mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
sudo apt install -y nginx php php-mysql php-curl php-gd mysql-server

# Configure MySQL
# We are going to create a user and a database for WordPress. This database user will have full access to that database.
echo "Configure MySQL"
mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE USER '$WP_DB_USERNAME'@'localhost' IDENTIFIED BY '$WP_DB_PASSWORD';
CREATE DATABASE $WP_DB_NAME;
GRANT ALL ON $WP_DB_NAME.* TO '$WP_DB_USERNAME'@'localhost';
EOF

# Configure nginx
# We are going to stick to the convention used by Ubuntu and create a new
# configuration file for the website at /etc/nginx/sites-available/domain.com
# and symlink it as /etc/nginx/sites-enabled/domain.com.
echo "Configure nginx"
sudo mkdir -p $WP_PATH/public $WP_PATH/logs
sudo tee /etc/nginx/sites-available/$WP_DOMAIN <<EOF
server {
  listen 80;
  server_name $WP_DOMAIN www.$WP_DOMAIN;

  root $WP_PATH/public;
  index index.php;

  access_log $WP_PATH/logs/access.log;
  error_log $WP_PATH/logs/error.log;

  location / {
    try_files \$uri \$uri/ /index.php?\$args;
  }

  location ~ \.php\$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php7.0-fpm.sock;
  }
}
EOF
sudo ln -s /etc/nginx/sites-available/$WP_DOMAIN /etc/nginx/sites-enabled/$WP_DOMAIN
sudo systemctl restart nginx

# Install WordPress
# Next, we fetch the latest version of the WordPress source code and unarchive it into $WP_PATH.
echo "Install WordPress"
sudo rm -rf $WP_PATH/public/ # !!!
sudo mkdir -p $WP_PATH/public/
sudo chown -R $USER $WP_PATH/public/
cd $WP_PATH/public/

wget --quiet https://wordpress.org/latest.tar.gz
tar xf latest.tar.gz --strip-components=1
rm latest.tar.gz

mv wp-config-sample.php wp-config.php
sed -i s/database_name_here/$WP_DB_NAME/ wp-config.php
sed -i s/username_here/$WP_DB_USERNAME/ wp-config.php
sed -i s/password_here/$WP_DB_PASSWORD/ wp-config.php
echo "define('FS_METHOD', 'direct');" >> wp-config.php

sudo chown -R www-data:www-data $WP_PATH/public/

# Finally, let's perform the final step of the installation which is to choose
# a username and password for the admin user.
echo "Setup wp-user and wp-password"
curl --silent "http://$WP_DOMAIN/wp-admin/install.php?step=2" \
  --data-urlencode "weblog_title=$WP_DOMAIN"\
  --data-urlencode "user_name=$WP_ADMIN_USERNAME" \
  --data-urlencode "admin_email=$WP_ADMIN_EMAIL" \
  --data-urlencode "admin_password=$WP_ADMIN_PASSWORD" \
  --data-urlencode "admin_password2=$WP_ADMIN_PASSWORD" \
  --data-urlencode "pw_weak=1"
