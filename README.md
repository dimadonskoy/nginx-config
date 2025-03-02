# Nginx Installation and Configuration Script

This script automates the installation and configuration of the Nginx web server. It provides several functionalities including setting up virtual hosts, enabling user directories, configuring basic and PAM authentication, and enabling CGI scripting.

## Prerequisites

- Ubuntu/Debian-based system
- Root privileges

## Usage

Run the script with one of the following arguments:

- `install-nginx`: Installs Nginx if it is not already installed.
- `setup-virtual-host`: Sets up a virtual host. Prompts for the domain name.
- `enable-user-dir`: Enables user directories.
- `setup-auth`: Configures basic authentication using `htpasswd`. Prompts for the username.
- `setup-auth-pam`: Configures authentication using PAM.
- `enable-cgi`: Enables CGI scripting.
- `all`: Executes all the above steps sequentially.

### Example
