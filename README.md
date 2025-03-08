# Nginx Configuration Tool

<!-- ![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-orange)
![Bash](https://img.shields.io/badge/Bash-Scripts-green)
![Nginx](https://img.shields.io/badge/Nginx-Server-blue) -->
<img src="https://raw.githubusercontent.com/marwin1991/profile-technology-icons/refs/heads/main/icons/nginx.png" alt="Nginx" width="100" height="100">

This is a Bash script to automate the setup, configuration, and removal of Nginx virtual hosts, user directories, and authentication mechanisms. The script simplifies the process of managing Nginx on a server by offering options to install Nginx, create virtual hosts, enable user directories, and configure basic and PAM (Pluggable Authentication Modules) authentication.

## Features

- **Install Nginx**: Installs Nginx if not already installed.
- **Remove Nginx**: Removes Nginx, configuration files, and associated directories.
- **Create Virtual Host**: Creates a new virtual host configuration for a domain.
- **Enable User Directory**: Configures the server to serve user-specific directories (e.g., `/home/username/public_html`).
- **Enable Basic Authentication**: Configures basic HTTP authentication for a virtual host.
- **Enable PAM Authentication**: Configures PAM authentication for a virtual host.

## Prerequisites

- A server running Ubuntu or Debian-based distribution.
- Root or user that can run sudo .

## Installation

1. Clone this repository or download the script file.
2. Make the script executable:

    ```
        chmod +x nginx-configuration-tool.sh
    ```

## Usage

Run the script with appropriate options:

```bash
sudo ./nginx-configuration-tool.sh [option]
```

### Options

- `--install`: Installs Nginx.
- `--remove`: Removes Nginx and its configurations.
- `--create-virtual-host`: Creates a virtual host for the specified domain.
- `--enable-user-dir`: Enables user directory for the specified username.
- `--enable-basic-auth`: Enables basic authentication for the specified domain.
- `--enable-pam-auth`: Enables PAM authentication for the specified domain.

## Author

- Dmitri Donskoy
- crooper22@gmail.com