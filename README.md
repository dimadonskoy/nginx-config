# Nginx Configuration Tool

![Nginx Logo](https://img.icons8.com/color/48/000000/nginx.png) ![Bash Logo](https://img.icons8.com/plasticine/100/000000/bash.png)

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
- Root privileges (sudo).

## Installation

1. Clone this repository or download the script file.
2. Make the script executable:

    ```bash
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
- `--create-vhost <domain>`: Creates a virtual host for the specified domain.
- `--enable-userdir <username>`: Enables user directory for the specified username.
- `--enable-basic-auth <domain>`: Enables basic authentication for the specified domain.
- `--enable-pam-auth <domain>`: Enables PAM authentication for the specified domain.

### Examples

- To install Nginx:

  ```bash
  sudo ./nginx-configuration-tool.sh --install
  ```

- To create a virtual host for `example.com`:

  ```bash
  sudo ./nginx-configuration-tool.sh --create-vhost example.com
  ```

- To enable user directory for `john`:

  ```bash
  sudo ./nginx-configuration-tool.sh --enable-userdir john
  ```

- To enable basic authentication for `example.com`:

  ```bash
  sudo ./nginx-configuration-tool.sh --enable-basic-auth example.com
  ```

- To enable PAM authentication for `example.com`:

  ```bash
  sudo ./nginx-configuration-tool.sh --enable-pam-auth example.com
  ```
