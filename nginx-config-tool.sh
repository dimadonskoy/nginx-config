#!/usr/bin/env bash

#######################################################################
#  _   _  _____ _____ _   ___   __  _______ ____   ____  _      
# | \ | |/ ____|_   _| \ | \ \ / / |__   __/ __ \ / __ \| |     
# |  \| | |  __  | | |  \| |\ V /     | | | |  | | |  | | |     
# | . ` | | |_ | | | . ` | > <      | | | | |  | | |  | | |     
# | |\  | |__| |_| |_| |\  |/ . \     | | | |__| | |__| | |____ 
# |_| \_|\_____|_____|_| \_/_/ \_\    |_|  \____/ \____/|______|

#######################################################################     

#Developed by : Dmitri Donskoy
#Purpose : Nginx configuration tool
#Date : 08.03.2025
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

#######################################################################

# Create LOGS directory if  not exist
if [ ! -d "/var/log/nginx-tool" ]; then
    echo "LOGS directory does not exist. Creating LOGS directory..."
    mkdir -p /var/log/nginx-tool
fi

## Log file
LOGFILE=/var/log/nginx-tool/nginx_tool.log


# Check if user is root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root" 
fi


# Install nginx service
function install_nginx(){
  if [ -x "$(command -v nginx)" ]; then
      echo "Nginx already installed. Skipping installation..." | tee -a $LOGFILE
  else
      echo "Installing nginx..." | tee -a $LOGFILE
      sudo apt update && apt install nginx -y | tee -a $LOGFILE
      echo "Nginx installed!" | tee -a $LOGFILE
  fi
} 

# Remove nginx service
function remove_nginx(){
  if [ -x "$(command -v nginx)" ]; then
      echo "Nginx installed. Uninstalling nginx service..." | tee -a $LOGFILE
      sudo apt remove nginx --purge -y | tee -a $LOGFILE
      rm -rf /etc/nginx/sites-available/* | tee -a $LOGFILE
      rm -rf /etc/nginx/sites-enabled/* | tee -a $LOGFILE
      rm -rf /var/www/* | tee -a $LOGFILE
      rm -rf /etc/nginx/.htpasswd | tee -a $LOGFILE
      rm -rf /var/log/nginx-tool | tee -a $LOGFILE
      rm -rf $USER_HOME_DIR/public_html/index.html | tee -a $LOGFILE
      echo "Nginx uninstalled!" | tee -a $LOGFILE
  fi
} 


######################################################################
### create a new virtual host with basic params
function create_virtual_host(){
    ### get the domain name
    read -p "Enter the domain name for the new virtual host : " domain_name

    ### check if virtual host already exists
    if [ -e /etc/nginx/sites-enabled/$domain_name ]; then
        echo "Virtual host already exists. Exiting..." | tee -a $LOGFILE
        exit 1
    fi

    echo "Creating new virtual host..." | tee -a $LOGFILE

    ### create site-directory
    mkdir -p /var/www/$domain_name | tee -a $LOGFILE
    sudo chown -R $USERNAME:$USERNAME /var/www/$domain_name | tee -a $LOGFILE
    sudo chmod -R 755 /var/www/$domain_name | tee -a $LOGFILE

    ### create sample index.html
    cat > /var/www/$domain_name/index.html <<EOF
    <H1>Welcome to $domain_name new virtual host</H1> 
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
        sudo rm /etc/nginx/sites-enabled/default | tee -a $LOGFILE
    fi

    ### check if virtual host already exists , if exist then exit
    if [ -e /etc/nginx/sites-enabled/$domain_name ]; then
        echo "Virtual host already exists. Exiting..." | tee -a $LOGFILE
        exit 1
    fi

    ### Create link to the site directory and set permissions
    ln -s /etc/nginx/sites-available/$domain_name /etc/nginx/sites-enabled/ | tee -a $LOGFILE
    chown -R $USERNAME:$USERNAME /etc/nginx/sites-available/$domain_name | tee -a $LOGFILE
    chmod -R 755 /etc/nginx/sites-available/$domain_name | tee -a $LOGFILE


    ### Add new virtual host to /etc/hosts
    echo "127.0.0.1 $domain_name" >> /etc/hosts | tee -a $LOGFILE

    ### restart nginx
    systemctl restart nginx | tee -a $LOGFILE

    echo "Virtual host created!" | tee -a $LOGFILE
    echo "You can access your website at http://$domain_name" | tee -a $LOGFILE

    ### Test with curl
    echo "Testing the virtual host with curl..." | tee -a $LOGFILE
    curl http://$domain_name | tee -a $LOGFILE

}

########################################  USER DIRECTORY  #########################################
function enable_user_dir() {
    read -p "Enter the domain name for the virtual host to enable user directory : " domain_name

    if [ ! -e "/etc/nginx/sites-enabled/$domain_name" ]; then
        echo "Virtual host does not exist. Please create a virtual host first." | tee -a $LOGFILE
        exit 1    
    fi

    # Create user directory if it does not exist
    mkdir -p "$USER_HOME_DIR/public_html" | tee -a $LOGFILE

    # Create a sample index.html
    cat > "$USER_HOME_DIR/public_html/index.html" <<EOF
    <H1>Welcome to nginx user_dir test server !</H1> 
EOF
    ## Set permissions
    sudo chown -R "$USERNAME:$USERNAME" "$USER_HOME_DIR/public_html" | tee -a $LOGFILE
    sudo chmod 755 $USER_HOME_DIR/public_html | tee -a $LOGFILE
    sudo chmod 644 $USER_HOME_DIR/public_html/index.html | tee -a $LOGFILE


    # Add user_dir configuration to Nginx
    sudo sed -i '13i\
        location ~ ^/~(.+?)(/.*)?$ {\n\
            alias /home/\$1/public_html/$2;\n\
            index index.html index.htm;\n\
        }' "/etc/nginx/sites-available/$domain_name" | tee -a $LOGFILE

    # Restart Nginx
    systemctl restart nginx | tee -a $LOGFILE

    echo "Virtual host configured!" | tee -a $LOGFILE
    echo "You can access your website at http://$domain_name/~$USERNAME" | tee -a $LOGFILE

    ### Test with curl
    echo "Testing the virtual host user_dir with curl..." | tee -a $LOGFILE
    curl http://$domain_name/~$USERNAME/ | tee -a $LOGFILE
}


##############################  BASIC AUTHENTICATION  #############################################
function enable_basic_auth() {
    echo "Setting up basic authentication..." | tee -a $LOGFILE
    sudo apt install -y apache2-utils nginx-extras | tee -a $LOGFILE

    read -p "Enter the domain name for the virtual host to enable basic auth : " domain_name

    ### check if virtual host already exists
    if [ ! -e "/etc/nginx/sites-enabled/$domain_name" ]; then
        echo "Virtual host does not exist. Please create a virtual host first." | tee -a $LOGFILE
        exit 1    
    fi

    ## create a password file
    echo "Enter the username :"
    read username
    htpasswd -c /etc/nginx/.htpasswd $username | tee -a $LOGFILE

    ### add basic auth to the virtual host
    sudo sed -i '13i\
        location /secure {\n\
            auth_basic "Restricted Area";\n\
            auth_basic_user_file /etc/nginx/.htpasswd;\n\
          }' /etc/nginx/sites-available/$domain_name | tee -a $LOGFILE

    ### restart nginx
    systemctl restart nginx | tee -a $LOGFILE
    
    echo "Basic authentication enabled !" | tee -a $LOGFILE
    echo "You can access your secure website at http://$domain_name/secure" | tee -a $LOGFILE

    ### Test with curl
    echo "Testing the virtual host with curl..." | tee -a $LOGFILE
    read -p "Enter the username : " auth_user
    read -p "Enter the password : " auth_pass
    curl -u auth_user:auth_pass http://$domain_name/secure/ | tee -a $LOGFILE

  }

################################  PAM AUTHENTICATION  ##############################################
function enable_auth_pam() {
    echo "Setting up PAM authentication..." | tee -a $LOGFILE
    sudo apt install -y libpam0g-dev libpam-modules | tee -a $LOGFILE

    read -p "Enter the domain name for the virtual host to enable PAM auth : " domain_name

    ### check if virtual host already exists
    if [ ! -e "/etc/nginx/sites-enabled/$domain_name" ]; then
        echo "Virtual host does not exist. Please create a virtual host first." | tee -a $LOGFILE
        exit 1    
    fi

    ### add pam auth to the virtual host
    sudo sed -i '13i\
        location /auth-pam {\n\
            auth_pam "PAM Authentication";\n\
            auth_pam_service_name "nginx";\n\
          }' /etc/nginx/sites-available/$domain_name | tee -a $LOGFILE


    # Define the PAM configuration file for nginx
    PAM_FILE="/etc/pam.d/nginx"

    # Append PAM configuration to nginx PAM file
    if ! grep -q "auth include common-auth" "$PAM_FILE"; then
        echo -e "auth include common-auth\naccount include common-account" | sudo tee -a "$PAM_FILE" | tee -a $LOGFILE
    fi

    # Add nginx user to shadow group
    sudo usermod -aG shadow www-data | tee -a $LOGFILE

    # Reload nginx service
    sudo systemctl reload nginx | tee -a $LOGFILE

    # Set permissions for the web directory
    sudo chown -R www-data:www-data /var/www/$domain_name | tee -a $LOGFILE
    sudo chmod -R 755 /var/www/$domain_name | tee -a $LOGFILE

    sudo systemctl restart nginx | tee -a $LOGFILE
    echo "PAM authentication enabled." | tee -a $LOGFILE

    ### Test with curl
    echo "Testing the virtual host with curl..." | tee -a $LOGFILE
    read -p "Enter the username : " auth_user
    read -p "Enter the password : " auth_pass
    curl -u auth_user:auth_pass http://$domain_name/auth-pam/ | tee -a $LOGFILE
}   


################################################################ OPTIONS ###################################################################


# Options to run the script
if [ $# -eq 0 ]; then
    echo "Please choose one of this options: $0 {--install | --create-virtual-host | --enable-user-dir | --setup-basic-auth | --setup-auth-pam | --remove}" | tee -a $LOGFILE
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
        echo "Please choose one of this options: $0 {--install | --create-virtual-host | --enable-user-dir | --setup-basic-auth | --setup-auth-pam | --remove}" | tee -a $LOGFILE
        exit 1
        ;;
esac