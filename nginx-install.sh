#!/usr/bin/env bash
#######################################################################
#Developed by : Dmitri Donskoy
#Purpose : Install and configure nginx server
#Date : 00.02.2025
#Version : 0.0.1
# set -x
set -o errexit
set -o nounset
set -o pipefail
#######################################################################

# # Get the home directory of the current user who run sudo .
# USER_HOME=$(eval echo ~$SUDO_USER)  

# Check if user is root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi


# Create LOGS directory if  not exist
if [ ! -d "/var/log/nginx_install" ]; then
    echo "LOGS directory does not exist. Creating LOGS directory..."
    mkdir -p /var/log/nginx_install
fi

LOGFILE=/var/log/nginx_install/nginx_install.log

# Install nginx service
function install_nginx(){
  if [ -x "$(command -v nginx)" ]; then
      echo "Nginx already installed. Skipping installation..."
  else
      echo "Installing nginx..."
      sudo apt update && apt install nginx -y
      echo "Nginx installed!"
  fi
}

######################################################################
### create a new virtual host
function create_virtual_host(){
    echo "Enter the domain name for the new virtual host : "
    read vhost_name

    ### CHECK IF Virtual host already exists
    if [ -e /etc/nginx/sites-available/$vhost_name ]; then
        echo "Virtual host already exists. Exiting..."
        exit 1
    fi

    echo "Creating new virtual host...".

    ### create site-directory
    mkdir -p /var/www/$vhost_name
    sudo chown -R $USER:$USER /var/www/$vhost_name
    sudo chmod -R 755 /var/www/$vhost_name

    ### create sample index.html
    cat > /var/www/$vhost_name/index.html <<EOF
    <H1>Welcome to $vhost_name</H1> 
EOF

    ### create a new virtual host
    cat > /etc/nginx/sites-available/$vhost_name <<EOF
    server {
        listen 80;
        listen [::]:80;

        root /var/www/$vhost_name;
        index index.html index.htm index.nginx-debian.html;

        server_name $vhost_name www.$vhost_name;

        location / {
            try_files \$uri \$uri/ =404;
        }
    }
EOF

######################################################################
    ### create a symbolic link
    if [ -e /etc/nginx/sites-enabled/default ]; then
        sudo rm /etc/nginx/sites-enabled/default
    fi

    if [ -e /etc/nginx/sites-enabled/$vhost_name ]; then
        echo "Virtual host already exists. Exiting..."
        exit 1
    fi

    ln -s /etc/nginx/sites-available/$vhost_name /etc/nginx/sites-enabled/
    systemctl restart nginx

    echo "New virtual host created!"
    echo "You can access your website at http://$vhost_name"

    ln -s /etc/nginx/sites-available/$vhost_name.conf /etc/nginx/sites-enabled/
    chown -R $USER:$USER /etc/nginx/sites-available/$vhost_name
    chmod -R 755 /etc/nginx/sites-available/$vhost_name.conf

    ### restart nginx
    systemctl restart nginx

    echo "New virtual host created!"
    echo "You can access your website at http://$vhost_name"
}

# Call function to install nginx
install_nginx

### call function to create virtual host
create_virtual_host

# ln -s /etc/nginx/sites-available/$vhost_name /etc/nginx/sites-enabled/
# sudo systemctl restart nginx
# echo "New virtual host created!"
# echo "You can access your website at http://$vhost_name"


# # Call func for install nginx 
# # install_nginx
# # create_virtual_host




# # ln -s /etc/nginx/sites-available/$vhost_name /etc/nginx/sites-enabled/
# # systemctl restart nginx




