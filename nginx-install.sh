#!/usr/bin/env bash

#######################################################################
#  _   _  _____ _____ _   ___   __  _______ ____   ____  _      
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


############################ GLOBAL VARS ##############################
# Get the home directory of the current user who run sudo .
USER_HOME_DIR=$(eval echo ~$SUDO_USER)  
# Get the username of the current user who run sudo .
USERNAME=$(basename $USER_HOME_DIR)
## Log file
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
      rm -rf /etc/nginx/sites-available/*
      rm -rf /etc/nginx/sites-enabled/*
      rm -rf /var/www/*
      rm -rf /etc/nginx/.htpasswd
      rm -rf /var/log/nginx_install
      rm -rf $USER_HOME_DIR/public_html/index.html
      echo "Nginx uninstalled!"
  fi
} 



######################################################################
### create a new virtual host with basic params
function create_virtual_host(){
    echo "Enter the domain name for the new virtual host : "
    read domain_name

    ### check if virtual host already exists
    if [ -e /etc/nginx/sites-enabled/$domain_name ]; then
        echo "Virtual host already exists. Exiting..."
        exit 1
    fi

    echo "Creating new virtual host...".

    ### create site-directory
    mkdir -p /var/www/$domain_name
    sudo chown -R $USER:$USER /var/www/$domain_name
    sudo chmod -R 755 /var/www/$domain_name

    ### create sample index.html
    cat > /var/www/$domain_name/index.html <<EOF
    <H1>Welcome to nginx new virtual host</H1> 
EOF

    ### create a new virtual host from template
    cat > /etc/nginx/sites-available/$domain_name <<EOF
    server {
        listen 80;
        listen [::]:80;

        root /var/www/$domain_name;
        index index.html index.htm index.nginx-debian.html;

        server_name $domain_name www.$domain_name;

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
    if [ -e /etc/nginx/sites-enabled/$domain_name ]; then
        echo "Virtual host already exists. Exiting..."
        exit 1
    fi

    ### Create link to the site directory and set permissions
    ln -s /etc/nginx/sites-available/$domain_name /etc/nginx/sites-enabled/
    chown -R $USER:$USER /etc/nginx/sites-available/$domain_name
    chmod -R 755 /etc/nginx/sites-available/$domain_name


    ### Add new virtual host to /etc/hosts
    echo "127.0.0.1 $domain_name" >> /etc/hosts

    ### restart nginx
    systemctl restart nginx

    echo "Virtual host created!"
    echo "You can access your website at http://$domain_name"

    ### Test with curl
    echo "Testing the virtual host with curl..."
    curl  http://$domain_name

}

##################  USER DIRECTORY  ####################################
function enable_user_dir() {
    echo "Enter the domain name for the virtual host to enable user directory: "
    read domain_name

    if [ ! -e "/etc/nginx/sites-enabled/$domain_name" ]; then
        echo "Virtual host does not exist. Please create a virtual host first."
        exit 1    
    fi

    # Create user directory if it does not exist
    mkdir -p "$USER_HOME_DIR/public_html"

    # Create a sample index.html
    cat > "$USER_HOME_DIR/public_html/index.html" <<EOF
    <H1>Welcome to nginx user_dir test server !</H1> 
EOF
    ## Set permissions
    sudo chown -R "$USERNAME:$USERNAME" "$USER_HOME_DIR/public_html"
    sudo chmod 755 $USER_HOME_DIR/public_html
    sudo chmod 644 $USER_HOME_DIR/public_html/index.html


    # Add user_dir configuration to Nginx
    sudo sed -i '13i\
        location ~ ^/~(.+?)(/.*)?$ {\n\
            alias /home/\$1/public_html/$2;\n\
            index index.html index.htm;\n\
        }' "/etc/nginx/sites-available/$domain_name"

    # Restart Nginx
    systemctl restart nginx

    echo "Virtual host configured!"
    echo "You can access your website at http://$domain_name/~$USERNAME"

    ### Test with curl
    echo "Testing the virtual host with curl..."
    curl http://$domain_name/~$USERNAME/
}



function basic_auth() {
    # Ensure apache2-utils is installed
    if ! [ -x "$(command -v htpasswd)" ]; then
        echo "Installing nginx extensions ..."
        sudo apt update && sudo apt install apache2-utils nginx-extras -y
    fi

    echo "Enter the domain name for the virtual host to enable basic auth : "
    read domain_name

    ## create a password file
    echo "Enter the username :"
    read username
    htpasswd -c /etc/nginx/.htpasswd $username

    ### add basic auth to the virtual host
    sudo sed -i '13i\
        location /secure {\n\
            auth_basic "Restricted Area";\n\
            auth_basic_user_file /etc/nginx/.htpasswd;\n\
          }' /etc/nginx/sites-available/$domain_name

    ### restart nginx
    systemctl restart nginx
    
    echo "Basic authentication enabled !"
    echo "You can access your secure website at http://$domain_name/secure"

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
    --enable-basic-auth)
        basic_auth
        ;;
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