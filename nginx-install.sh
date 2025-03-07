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
    read -p "Enter the domain name for the new virtual host : " domain_name

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
    read -p "Enter the domain name for the virtual host to enable user directory : " domain_name

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


##################  BASIC AUTHENTICATION  ####################################
function enable_basic_auth() {
    echo "Setting up basic authentication..."
    sudo apt install -y apache2-utils nginx-extras

    read -p "Enter the domain name for the virtual host to enable basic auth : " domain_name

    ### check if virtual host already exists
    if [ ! -e "/etc/nginx/sites-enabled/$domain_name" ]; then
        echo "Virtual host does not exist. Please create a virtual host first."
        exit 1    
    fi

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

    ### Test with curl
    echo "Testing the virtual host with curl..."
    read -p "Enter the username : " auth_user
    read -p "Enter the password : " auth_pass
    curl -u auth_user:auth_pass http://$domain_name/secure/

  }

##################  PAM AUTHENTICATION  ####################################
function enable_auth_pam() {
    echo "Setting up PAM authentication..."
    sudo apt install -y libpam0g-dev libpam-modules

    ### add pam auth to the virtual host
    sudo sed -i '13i\
        location /auth-pam {\n\
            auth_pam "PAM Authentication";\n\
            auth_pam_service_name "nginx";\n\
          }' /etc/nginx/sites-available/$domain_name


    # Define the PAM configuration file for nginx
    PAM_FILE="/etc/pam.d/nginx"
    NGINX_GROUP="www-data"
    HTML_DIR="/var/www/html/$domain_name"
    HTML_FILE="$HTML_DIR/index.html"

    # Append PAM configuration to nginx PAM file
    if ! grep -q "auth include common-auth" "$PAM_FILE"; then
        echo -e "auth include common-auth\naccount include common-account" | sudo tee -a "$PAM_FILE"
    fi

    # Add nginx user to shadow group
    sudo usermod -aG shadow "$NGINX_GROUP"

    # Reload nginx service
    sudo systemctl reload nginx

    # Create test directory and index.html file
    sudo mkdir -p "$HTML_DIR"
    echo "<html>
    <body>
    <div style='width: 100%; font-size: 40px; font-weight: bold; text-align: center;'>
    Test Page for PAM Auth
    </div>
    </body>
    </html>" | sudo tee "$HTML_FILE"

    # Set permissions for the web directory
    sudo chown -R www-data:www-data "$HTML_DIR"
    sudo chmod -R 755 "$HTML_DIR"

    sudo ln -s /etc/nginx/sites-available/auth_pam /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
    echo "PAM authentication enabled."
}   


########################################### OPTIONS ################################################


# Options to run the script
if [ $# -eq 0 ]; then
    echo "Please choose one of this options: $0 {--install-nginx | --create-virtual-host | --enable-user-dir | --setup-basic-auth | --setup-auth-pam | --remove-nginx}"
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
        enable_basic_auth
        ;;
    --enable-auth-pam)
        enable_auth_pam
        ;;
    --remove)
        remove_nginx
        ;;

    *)
        echo "Usage: $0 {install-nginx | create-virtual-host | enable-user-dir | setup-basic-auth | setup-auth-pam | remove-nginx}"
        exit 1
        ;;
esac