#!/usr/bin/env bash

#######################################################################
  _   _  _____ _____ _   ___   __  _______ ____   ____  _      
# | \ | |/ ____|_   _| \ | \ \ / / |__   __/ __ \ / __ \| |     
# |  \| | |  __  | | |  \| |\ V /     | | | |  | | |  | | |     
# | . ` | | |_ | | | | . ` | > <      | | | |  | | |  | | |     
# | |\  | |__| |_| |_| |\  |/ . \     | | | |__| | |__| | |____ 
# |_| \_|\_____|_____|_| \_/_/ \_\    |_|  \____/ \____/|______|

#######################################################################     

#Developed by : Dmitri Donskoy
#Purpose : Install and configure nginx server
#Date : 00.02.2025
#Version : 0.0.1
# set -x
set -o errexit
set -o nounset
set -o pipefail


############################ VARS ######################################
# Get the home directory of the current user who run sudo .
USER_HOME_DIR=$(eval echo ~$SUDO_USER)  
# Get the username of the current user who run sudo .
USERNAME=$(basename $USER_HOME_DIR)

LOGFILE=/var/log/nginx_install/nginx_install.log
#######################################################################

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

# Remove nginx service
function remove_nginx(){
  if [ -x "$(command -v nginx)" ]; then
      echo "Nginx installed. Uninstalling nginx service..."
      sudo apt remove nginx --purge -y
      echo "Nginx uninstalled!"
  fi
} 



######################################################################
### create a new virtual host with basic params
function create_virtual_host(){
    echo "Enter the domain name for the new virtual host : "
    read vhost_name

    ### check if virtual host already exists
    if [ -e /etc/nginx/sites-enabled/$vhost_name ]; then
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

    ### create a new virtual host from template
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

    ### remove default virtual host from sites-enabled if exists
    if [ -e /etc/nginx/sites-enabled/default ]; then
        sudo rm /etc/nginx/sites-enabled/default
    fi

    ### check if virtual host already exists , if exist then exit
    if [ -e /etc/nginx/sites-enabled/$vhost_name ]; then
        echo "Virtual host already exists. Exiting..."
        exit 1
    fi

    ### Create link to the site directory and set permissions
    ln -s /etc/nginx/sites-available/$vhost_name /etc/nginx/sites-enabled/
    chown -R $USER:$USER /etc/nginx/sites-available/$vhost_name
    chmod -R 755 /etc/nginx/sites-available/$vhost_name

    ### restart nginx
    systemctl restart nginx

    echo "Virtual host created!"
    echo "You can access your website at http://$vhost_name"

}


function enable_user_dir() {
    echo "Enter the domain name for the virtual host to enable user directory: "
    read vhost_name

    ### check if virtual host already exists , if exist then exit
    if [ -e /etc/nginx/sites-enabled/$vhost_name ]; then
        echo "Virtual host already exists. Exiting..."
        exit 1
    fi

    ### create site-directory
    mkdir -p /var/www/$vhost_name
    sudo chown -R $USER:$USER /var/www/$vhost_name
    sudo chmod -R 755 /var/www/$vhost_name

    ### create sample index.html
    cat > /var/www/$vhost_name/index.html <<EOF
    <H1>Welcome to $vhost_name</H1> 
EOF

    cat > /etc/nginx/sites-available/"$vhost_name" <<EOF
    server {
        listen 80;
        listen [::]:80;

        root /var/www/$vhost_name;
        index index.html index.htm index.nginx-debian.html;

        server_name $vhost_name www.$vhost_name;

        location ~ ^/~(.+?)(/.*)?$ {
            alias /home/\$1/public_html/\$2;
            index index.html index.htm;
        }
    }
EOF

    ### Create link to the site directory and set permissions
    rm -rf /etc/nginx/sites-enabled/* ## remove all enabled sites
    
    ln -s /etc/nginx/sites-available/$vhost_name /etc/nginx/sites-enabled/
    chown -R $USERNAME:$USERNAME /etc/nginx/sites-available/$vhost_name
    chmod -R 755 /etc/nginx/sites-available/$vhost_name

    ### restart nginx
    systemctl restart nginx

    echo "Virtual host created!"
    echo "You can access your website at http://$vhost_name/~$USERNAME"

}

########################################### OPTIONS ################################################


# Options to run the script
if [ $# -eq 0 ]; then
    echo "Please choose one of this options. Usage: $0 {install-nginx|setup-virtual-host|enable-user-dir|setup-auth|setup-auth-pam|enable-cgi|remove nginx}"
    exit 1
fi


case "$1" in
    --install)
        install_nginx
        ;;
    --create-virtual-host)
        create_virtual_host
        ;;
    --enable-user-dir)
        enable_user_dir
        ;;
    # setup-auth)
    #     setup_auth
    #     ;;
    # setup-auth-pam)
    #     setup_auth_pam
    #     ;;
    # enable-cgi)
    #     enable_cgi
    #     ;;
    --remove)
        remove_nginx
        ;;

    *)
        echo "Usage: $0 {install-nginx|setup-virtual-host|enable-user-dir|setup-auth|setup-auth-pam|enable-cgi|remove-nginx}"
        exit 1
        ;;
esac

# ./setup_nginx.sh install-nginx         # Install Nginx
# ./setup_nginx.sh remove-nginx          # Uninstall Nginx
# ./setup_nginx.sh create-virtual-host   # Configure a virtual host
# ./setup_nginx.sh enable-user-dir       # Enable user directories
# ./setup_nginx.sh setup-auth            # Enable authentication (htpasswd)
# ./setup_nginx.sh setup-auth-pam        # Enable PAM authentication
# ./setup_nginx.sh enable-cgi            # Enable CGI scripting
