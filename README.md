# 🚀 Nginx Configuration Tool

[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)](https://www.nginx.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)

This Bash script automates the setup and configuration of Nginx. It can install or remove Nginx, create virtual hosts, enable user directories, configure CGI, and set up both basic and PAM authentication.

## 📁 Features

- 🟢 **Install Nginx** if not present
- 🔴 **Remove Nginx** and all configs
- 🌐 **Create Virtual Host** for a domain
- 👤 **Enable User Directory** support
- 🔒 **Enable Basic Authentication**
- 🔑 **Enable PAM Authentication**
- ⚙️ **Enable CGI module** for scripts

## ⚙️ Prerequisites

- 🐧 **Supported OS:** Ubuntu 20.04/22.04 or Debian 10/11
- 🔑 **Privileges:** Root or sudo user
- 📦 **Dependencies:** `curl`, `openssl`, `htpasswd` (`apache2-utils`)

Install dependencies if missing:

```bash
sudo apt update
sudo apt install curl openssl apache2-utils
```

## 🚀 Installation

1. **Clone the repository:**
    ```bash
    git clone https://github.com/dimadonskoy/nginx-config.git
    ```
2. **Make the script executable:**
    ```bash
    chmod +x nginx-config-tool.sh
    ```

## 🛠️ Usage

Run the script with the desired option:

```bash
sudo ./nginx-config-tool.sh --[option]
```

### Options

- `--install`    Install Nginx
- `--remove`    Remove Nginx and configs
- `--vhost`     Create a virtual host
- `--user-dir`   Enable user directory
- `--basic-auth`  Enable basic authentication
- `--pam-auth`   Enable PAM authentication
- `--cgi`      Enable CGI module

## 📝 Example Commands

```bash
sudo ./nginx-config-tool.sh --install
sudo ./nginx-config-tool.sh --vhost example.com
sudo ./nginx-config-tool.sh --user-dir username
sudo ./nginx-config-tool.sh --basic-auth example.com
```

## 🔍 Troubleshooting

- Check Nginx status:
  ```bash
  sudo systemctl status nginx
  ```
- Test Nginx configuration:
  ```bash
  sudo nginx -t
  ```
- View logs:
  ```bash
  sudo journalctl -u nginx
  ```

## 👨‍💻 Author

**Dmitri Donskoy**  
📧 crooper22@gmail.com
