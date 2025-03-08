# Nginx Configuration Tool

<p align="center">
    <img src="https://raw.githubusercontent.com/marwin1991/profile-technology-icons/refs/heads/main/icons/nginx.png" alt="Nginx" width="70" height="70">
    <img src="https://raw.githubusercontent.com/marwin1991/profile-technology-icons/refs/heads/main/icons/bash.png" alt="Bash" width="70" height="70">
</p>

This is a Bash script to automate the setup, and configuration of Nginx . The script install/remove Nginx, create virtual hosts, enable user directories, CGI and configure basic and PAM authentication.

## Features

- **Install Nginx**: Installs Nginx if not already installed.
- **Remove Nginx**: Removes Nginx, configuration files, and associated directories.
- **Create Virtual Host**: Creates a new virtual host configuration for a domain.
- **Enable User Directory**: Configures the server to serve user-specific directories.
- **Enable Basic Authentication**: Configures basic HTTP authentication for a virtual host.
- **Enable PAM Authentication**: Configures PAM authentication for a virtual host.
- **Enable CGI module**: Configures CGI module for a virtual host.

## Prerequisites

- A server running Ubuntu or Debian-based distribution.
- Root or user that can run sudo .

## Installation

- Clone this repository or download the script file.

```
git clone https://github.com/dimadonskoy/nginx-config.git
```
- Make the script executable:

```
chmod +x nginx-configuration-tool.sh
```

## Usage

Run the script with appropriate options:

```bash
sudo ./nginx-config-tool.sh --[option]
```

## Options

- `--install`: Installs Nginx.
- `--remove`: Removes Nginx and its configurations.
- `--vhost`: Creates a virtual host for the specified domain.
- `--userdir`: Enables user directory for the specified username.
- `--basic-auth`: Enables basic authentication for the specified domain.
- `--pam-auth`: Enables PAM authentication for the specified domain.
- `--cgi`: Enables CGI module to run scripts .

## Author

- Dmitri Donskoy
- crooper22@gmail.com