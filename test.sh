#!/usr/bin/env bash

function basic_auth() {
    sudo sed -i '13i\
    location /secure {\n\
        auth_basic "Restricted Area";\n\
        auth_basic_user_file /etc/nginx/.htpasswd;\n\
    }' /etc/nginx/sites-available/facebook.com

    ## Restart Nginx
    sudo nginx -t && sudo systemctl reload nginx
}

basic_auth

