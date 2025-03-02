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


# Function to install Nginx if not installed
install_nginx() {
    if ! command -v nginx &> /dev/null; then
        echo "Nginx is not installed. Installing..."
        sudo apt update && sudo apt install -y nginx
        sudo systemctl enable nginx
        sudo systemctl start nginx
    else
        echo "Nginx is already installed."
    fi
}

# Function to set up a virtual host
setup_virtual_host() {
    read -p "Enter virtual host domain name (example.com): " domain
    conf_file="/etc/nginx/sites-available/$domain"

    if [[ -f "$conf_file" ]]; then
        echo "Virtual host already exists for $domain"
    else
        sudo mkdir -p "/var/www/$domain/html"
        echo "<h1>Welcome to $domain</h1>" | sudo tee "/var/www/$domain/html/index.html"

        sudo tee "$conf_file" > /dev/null <<EOL
server {
    listen 80;
    server_name $domain;
    
    root /var/www/$domain/html;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

        sudo ln -s "$conf_file" "/etc/nginx/sites-enabled/"
        sudo systemctl restart nginx
        echo "Virtual host $domain configured."
    fi
}

# Function to enable user directories
enable_user_dir() {
    echo "Enabling user directories..."
    sudo apt install -y nginx
    sudo mkdir -p /etc/nginx/user_dirs
    sudo tee /etc/nginx/sites-available/user_dirs > /dev/null <<EOL
server {
    listen 80;
    server_name _;

    location ~ ^/~(.+?)(/.*)?\$ {
        alias /home/\$1/public_html\$2;
        autoindex on;
    }
}
EOL
    sudo ln -s /etc/nginx/sites-available/user_dirs /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
    echo "User directories enabled."
}

# Function to configure basic authentication
setup_auth() {
    read -p "Enter username for authentication: " username
    sudo apt install -y apache2-utils
    sudo htpasswd -c /etc/nginx/.htpasswd "$username"

    sudo tee /etc/nginx/sites-available/auth > /dev/null <<EOL
server {
    listen 80;
    server_name _;

    location /secure/ {
        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
}
EOL
    sudo ln -s /etc/nginx/sites-available/auth /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
    echo "Basic authentication enabled."
}

# Function to configure authentication using PAM
setup_auth_pam() {
    echo "Setting up PAM authentication..."
    sudo apt install -y libnginx-mod-http-auth-pam
    sudo tee /etc/nginx/sites-available/auth_pam > /dev/null <<EOL
server {
    listen 80;
    server_name _;

    location /pam-secure/ {
        auth_pam "Secure Zone";
        auth_pam_service_name nginx;
    }
}
EOL
    sudo ln -s /etc/nginx/sites-available/auth_pam /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
    echo "PAM authentication enabled."
}

# Function to enable CGI scripting
enable_cgi() {
    echo "Enabling CGI scripting..."
    sudo apt install -y fcgiwrap
    sudo systemctl enable fcgiwrap
    sudo systemctl start fcgiwrap

    sudo tee /etc/nginx/sites-available/cgi > /dev/null <<EOL
server {
    listen 80;
    server_name _;

    location /cgi-bin/ {
        root /usr/lib/cgi-bin;
        fastcgi_pass unix:/var/run/fcgiwrap.socket;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOL
    sudo ln -s /etc/nginx/sites-available/cgi /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
    echo "CGI scripting enabled."
}

# Main logic to process script arguments
if [ $# -eq 0 ]; then
    echo "No arguments provided. Usage: $0 {install-nginx|setup-virtual-host|enable-user-dir|setup-auth|setup-auth-pam|enable-cgi|all}"
    exit 1
fi

case "$1" in
    install-nginx)
        install_nginx
        ;;
    setup-virtual-host)
        setup_virtual_host
        ;;
    enable-user-dir)
        enable_user_dir
        ;;
    setup-auth)
        setup_auth
        ;;
    setup-auth-pam)
        setup_auth_pam
        ;;
    enable-cgi)
        enable_cgi
        ;;
    all)
        install_nginx
        setup_virtual_host
        enable_user_dir
        setup_auth
        setup_auth_pam
        enable_cgi
        ;;
    *)
        echo "Usage: $0 {install-nginx|setup-virtual-host|enable-user-dir|setup-auth|setup-auth-pam|enable-cgi|all}"
        exit 1
        ;;
esac


# ./setup_nginx.sh install-nginx         # Install Nginx
# ./setup_nginx.sh setup-virtual-host    # Configure a virtual host
# ./setup_nginx.sh enable-user-dir       # Enable user directories
# ./setup_nginx.sh setup-auth            # Enable authentication (htpasswd)
# ./setup_nginx.sh setup-auth-pam        # Enable PAM authentication
# ./setup_nginx.sh enable-cgi            # Enable CGI scripting
# ./setup_nginx.sh all                    # Install and configure everything

# # Create LOGS directory if  not exist
# if [ ! -d "/var/log/nginx_install" ]; then
#     echo "LOGS directory does not exist. Creating LOGS directory..."
#     mkdir -p /var/log/nginx_install
# fi

# LOGFILE=/var/log/nginx_install/nginx_install.log

# # create function
# function install_nginx(){
#   if [ -x "$(command -v nginx)" ]; then
#       echo "Nginx already installed. Skipping installation..."
#   else
#       echo "Installing nginx..."
#       sudo apt update && apt install nginx -y
#       echo "Nginx installed!"
#   fi
# }

# install_nginx

# ### create a new virtual host

#   echo "Enter the domain name for the new virtual host : "
#   read vhost_name
#   echo "Creating new virtual host...".

#   ### create site-directory
#   mkdir -p /var/www/$vhost_name
#   sudo chown -R $USER:$USER /var/www/$vhost_name
#   sudo chmod -R 755 /var/www/$vhost_name

#   ### create sample index.html
#   cat > /var/www/$vhost_name/index.html <<EOF
#   <H1>Welcome to $vhost_name</H1>
# EOF

#   ### add server block to nginx
#     cat > /etc/nginx/sites-available/$vhost_name.conf <<EOF
#     server {
#         listen 80;
#         server_name $vhost_name www.$vhost_name;
        
#         root /var/www/$vhost_name;
#         index index.html index.htm index.php;
#     }
# EOF
#   sudo chown -R $USER:$USER /etc/nginx/sites-available/$vhost_name.conf
#   sudo chmod -R 755 /etc/nginx/sites-available/$vhost_name.conf

# ln -s /etc/nginx/sites-available/$vhost_name /etc/nginx/sites-enabled/
# sudo systemctl restart nginx
# echo "New virtual host created!"
# echo "You can access your website at http://$vhost_name"


# # Call func for install nginx 
# # install_nginx
# # create_virtual_host




# # ln -s /etc/nginx/sites-available/$vhost_name /etc/nginx/sites-enabled/
# # systemctl restart nginx




