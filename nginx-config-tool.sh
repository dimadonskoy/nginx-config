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
#Update date : 26.03.2025
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
      apt update && apt install nginx -y | tee -a $LOGFILE
      echo
      echo "Nginx installed!" | tee -a $LOGFILE
      echo
  fi
} 

######################################################################
### create a new virtual host with basic params
function create_virtual_host(){
    ### get the domain name
    read -p "Enter the domain name for the new virtual host: " domain_name

    ### check if virtual host already exists
    if [ -e /etc/nginx/sites-available/$domain_name ] || [ -e /etc/nginx/sites-enabled/$domain_name ]; then
        echo "Virtual host already exists. Exiting..." | tee -a "$LOGFILE"
        exit 1
    fi

    echo "Creating new virtual host..." | tee -a "$LOGFILE"

    ### create site-directory
    mkdir -p "/var/www/$domain_name"
    chown -R "$USERNAME:$USERNAME" "/var/www/$domain_name"
    chmod -R 755 "/var/www/$domain_name"

    ### create sample index.html
    echo "<h1>Welcome to $domain_name new virtual host</h1>" > "/var/www/$domain_name/index.html"

    ### Define template and output file
    template_file="./templates/vhost_template.conf"
    output_file="/etc/nginx/sites-available/$domain_name"

    ### Ensure template exists before proceeding
    if [ ! -s "$template_file" ]; then
        echo "Error: Template file $template_file is missing or empty!" | tee -a "$LOGFILE"
        exit 1
    fi

    ### Replace domain placeholder in template and create virtual host config
    sed "s/__DOMAIN_NAME__/$domain_name/g" "$template_file" > "$output_file"

    ### Remove default virtual host if it exists
    if [ -e /etc/nginx/sites-enabled/default ]; then
        rm /etc/nginx/sites-enabled/default
    fi

    ### Create symlink and set permissions
    ln -s "$output_file" "/etc/nginx/sites-enabled/"
    chown -R "$USERNAME:$USERNAME" "$output_file"
    chmod -R 755 "$output_file"

    ### Add domain to /etc/hosts if not already present
    if ! grep -q "$domain_name" /etc/hosts; then
        echo "127.0.0.1 $domain_name" >> /etc/hosts
    fi

    ### Test Nginx configuration before restarting
    if nginx -t; then
        systemctl restart nginx
        echo "Virtual host created successfully!" | tee -a "$LOGFILE"
        echo "You can access your website at http://$domain_name" | tee -a "$LOGFILE"

        ### Test with curl
        echo "Testing the virtual host with curl..." | tee -a "$LOGFILE"
        curl -s "http://$domain_name" | tee -a "$LOGFILE"
    else
        echo "Nginx configuration test failed! Check the logs." | tee -a "$LOGFILE"
        exit 1
    fi
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
    echo "<H1>Welcome to nginx user_dir test server !</H1>" > "$USER_HOME_DIR/public_html/index.html"

    ## Set permissions
    chown -R "$USERNAME:$USERNAME" "$USER_HOME_DIR/public_html" | tee -a $LOGFILE
    chmod o+x $USER_HOME_DIR | tee -a $LOGFILE 
    chmod 755 $USER_HOME_DIR/public_html | tee -a $LOGFILE
    chmod 644 $USER_HOME_DIR/public_html/index.html | tee -a $LOGFILE


    ### Define template and output file
    template_file="./templates/user_dir.conf"
    output_file="/etc/nginx/sites-available/$domain_name"

    ### Ensure template exists before proceeding
    if [ ! -s "$template_file" ]; then
        echo "Error: Template file $template_file is missing or empty!" | tee -a "$LOGFILE"
        exit 1
    fi

    ### Replace domain placeholder in template and create virtual host config
    sed "s/__DOMAIN_NAME__/$domain_name/g" "$template_file" > "$output_file"


    ### Test Nginx configuration before restarting
    if nginx -t; then
        systemctl restart nginx
        echo "Virtual host created successfully!" | tee -a "$LOGFILE"
        echo "You can access your website at http://$domain_name" | tee -a "$LOGFILE"

        echo "Testing the virtual host user_dir with curl..." | tee -a $LOGFILE
        curl http://$domain_name/~$USERNAME/ | tee -a $LOGFILE
        echo
    else
        echo "Nginx configuration test failed! Check the logs." | tee -a "$LOGFILE"
        exit 1
    fi
}

##############################  BASIC AUTHENTICATION  #############################################
function enable_basic_auth() {
    echo "Setting up basic authentication..." | tee -a $LOGFILE
    apt install -y apache2-utils nginx-extras | tee -a $LOGFILE

    ### get the domain name
    read -p "Enter the domain name for the virtual host to enable basic auth : " domain_name

    ### check if virtual host already exists
    if [ ! -e "/etc/nginx/sites-enabled/$domain_name" ]; then
        echo "Virtual host does not exist. Please create a virtual host first." | tee -a $LOGFILE
        exit 1    
    fi

    ## create a password file
    read -p "Enter the username : " username
    htpasswd -c /etc/nginx/.htpasswd $username | tee -a $LOGFILE


    # Create secure directory and index.html if it does not exist
    mkdir -p "/var/www/$domain_name/secure" | tee -a $LOGFILE

    # Create a sample index.html
    echo "<H1>Welcome to nginx $domain_name server !</H1>" > "/var/www/$domain_name/secure/index.html"

    ### Define template and output file
    template_file="./templates/basic_auth.conf"
    output_file="/etc/nginx/sites-available/$domain_name"

    ### Ensure template exists before proceeding
    if [ ! -s "$template_file" ]; then
        echo "Error: Template file $template_file is missing or empty!" | tee -a "$LOGFILE"
        exit 1
    fi

    ### Replace domain placeholder in template and create virtual host config
    sed "s/__DOMAIN_NAME__/$domain_name/g" "$template_file" > "$output_file"
 
    ### Test Nginx configuration before restarting
    if nginx -t; then
        systemctl restart nginx
        echo "Virtual host created successfully!" | tee -a "$LOGFILE"

        ### Test with curl
        echo
        echo "Testing the virtual host with curl..." | tee -a $LOGFILE
        read -p "Enter the username : " auth_user
        read -p "Enter the password : " auth_pass
        curl -u $auth_user:$auth_pass http://$domain_name/secure/ | tee -a $LOGFILE
        echo
    else
        echo "Nginx configuration test failed! Check the logs." | tee -a "$LOGFILE"
        exit 1
    fi

  }

################################  PAM AUTHENTICATION  ##############################################
function enable_auth_pam() {
    echo "Setting up PAM authentication..." | tee -a $LOGFILE
    apt install -y libpam0g-dev libpam-modules libnginx-mod-http-auth-pam | tee -a $LOGFILE

    read -p "Enter the domain name for the virtual host to enable PAM auth : " domain_name

    ### check if virtual host already exists
    if [ ! -e "/etc/nginx/sites-enabled/$domain_name" ]; then
        echo "Virtual host does not exist. Please create a virtual host first." | tee -a $LOGFILE
        exit 1    
    fi

    # Create auth-pam directory and index.html if it does not exist
    mkdir -p "/var/www/$domain_name/auth-pam" | tee -a $LOGFILE

    # Create a sample index.html
    echo "<H1>Welcome to nginx auth-pam_dir $domain_name server !</H1>" > "/var/www/$domain_name/auth-pam/index.html"

    ### Define template and output file
    template_file="./templates/pam_auth.conf"
    output_file="/etc/nginx/sites-available/$domain_name"

    ### Ensure template exists before proceeding
    if [ ! -s "$template_file" ]; then
        echo "Error: Template file $template_file is missing or empty!" | tee -a "$LOGFILE"
        exit 1
    fi

    ### Replace domain placeholder in template and create virtual host config
    sed "s/__DOMAIN_NAME__/$domain_name/g" "$template_file" > "$output_file"

    # Define the PAM configuration file for nginx
    PAM_FILE="/etc/pam.d/nginx"

    # Append PAM configuration to nginx PAM file
    if ! grep -q "auth include common-auth" "$PAM_FILE"; then
        echo -e "auth include common-auth\naccount include common-account" | tee -a "$PAM_FILE" | tee -a $LOGFILE
    fi

    # Add nginx user to shadow group
    usermod -aG shadow www-data | tee -a $LOGFILE

    # Reload nginx service
    systemctl restart nginx | tee -a $LOGFILE

    # Set permissions for the web directory
    chown -R www-data:www-data /var/www/$domain_name | tee -a $LOGFILE
    chmod -R 755 /var/www/$domain_name | tee -a $LOGFILE

    systemctl restart nginx | tee -a $LOGFILE
    echo "PAM authentication enabled." | tee -a $LOGFILE


    ### Test Nginx configuration before restarting
    if nginx -t; then
        systemctl restart nginx
        echo "Virtual host created successfully!" | tee -a "$LOGFILE"

    ### Test with curl
    echo
    echo "Testing the virtual host with curl..." | tee -a $LOGFILE
    read -p "Enter the username : " auth_user
    read -p "Enter the password : " auth_pass
    curl -u $auth_user:$auth_pass http://$domain_name/auth-pam/ | tee -a $LOGFILE
    echo

    else
        echo "Nginx configuration test failed! Check the logs." | tee -a "$LOGFILE"
        exit 1
    fi
}   

function enable_cgi(){
    echo "Setting up CGI..." | tee -a $LOGFILE
    apt install -y fcgiwrap spawn-fcgi | tee -a $LOGFILE

    read -p "Enter the domain name for the virtual host to enable CGI : " domain_name

    ### check if virtual host already exists
    if [ ! -e "/etc/nginx/sites-enabled/$domain_name" ]; then
        echo "Virtual host does not exist. Please create a virtual host first." | tee -a $LOGFILE
        exit 1    
    fi

    # Create cgi directory and index.html if it does not exist
    mkdir -p "/var/www/$domain_name/cgi" | tee -a $LOGFILE

    # Create a sample cgi script
    ### Define template and output file
    template_file="./templates/cgi_script.sh"
    output_file="/var/www/$domain_name/cgi/cgi_script.sh"

    ### Ensure template exists before proceeding
    if [ ! -s "$template_file" ]; then
        echo "Error: Template file $template_file is missing or empty!" | tee -a "$LOGFILE"
        exit 1
    fi

    ### Replace domain placeholder in template and create virtual host config
    sed "s/__DOMAIN_NAME__/$domain_name/g" "$template_file" > "$output_file"


    # Create virtualhost cgi
    ### Define template and output file
    template_file="./templates/cgi.conf"
    output_file="/etc/nginx/sites-available/$domain_name"

    ### Ensure template exists before proceeding
    if [ ! -s "$template_file" ]; then
        echo "Error: Template file $template_file is missing or empty!" | tee -a "$LOGFILE"
        exit 1
    fi

    ### Replace domain placeholder in template and create virtual host config
    sed "s/__DOMAIN_NAME__/$domain_name/g" "$template_file" > "$output_file"


    # Set permissions for the cgi script
    chmod +x /var/www/$domain_name/cgi/cgi_script.sh | tee -a $LOGFILE

    # Reload nginx service
    systemctl restart nginx | tee -a $LOGFILE

    # Set permissions for the web directory
    chown -R www-data:www-data /var/www/$domain_name | tee -a $LOGFILE
    chmod -R 755 /var/www/$domain_name | tee -a $LOGFILE

    systemctl restart nginx | tee -a $LOGFILE
    echo "CGI enabled." | tee -a $LOGFILE

    ### Test with curl
    echo
    echo "Testing the virtual host with curl..." | tee -a $LOGFILE
    curl http://$domain_name/cgi/cgi_script.sh | tee -a $LOGFILE
    echo
}

################################# REMOVE NGINX ############################################
# Remove nginx service
function remove_nginx(){
  if [ -x "$(command -v nginx)" ]; then
    echo "Nginx installed. Uninstalling nginx service..." | tee -a $LOGFILE
    apt remove nginx --purge -y | tee -a $LOGFILE
    rm -rf /etc/nginx/sites-available/* | tee -a $LOGFILE
    rm -rf /etc/nginx/sites-enabled/* | tee -a $LOGFILE
    rm -rf /var/www/* | tee -a $LOGFILE
    rm -rf /etc/nginx/.htpasswd | tee -a $LOGFILE
    rm -rf /etc/pam.d/nginx | tee -a $LOGFILE
    rm -rf /etc/nginx/.htpasswd | tee -a $LOGFILE
    rm -rf $USER_HOME_DIR/public_html/index.html | tee -a $LOGFILE
    echo
    echo "Nginx uninstalled!" | tee -a $LOGFILE
    echo
  fi
} 
################################################################ OPTIONS ###################################################################


# Options to run the script
if [ $# -eq 0 ]; then
    echo "Please choose one of this options: $0 {--install | --vhost | --user-dir | --basic-auth | --pam-auth | --cgi | --remove}" | tee -a $LOGFILE
    exit 1
fi


case "$1" in
    --install)
        install_nginx
        ;;
    --vhost)
        create_virtual_host
        ;;
    --user-dir)
        enable_user_dir
        ;;
    --basic-auth)
        enable_basic_auth
        ;;
    --pam-auth)
        enable_auth_pam
        ;;
    --cgi)
        enable_cgi
        ;;
    --remove)
        remove_nginx
        ;;

    *)
       echo "Please choose one of this options: $0 {--install | --vhost | --user-dir | --basic-auth | --pam-auth | --cgi | --remove}" | tee -a $LOGFILE
        exit 1
        ;;
esac