# 🚀 Automated Static Website Deployer

![License](https://img.shields.io/badge/license-Apache%202.0-blue)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey)
![Bash](https://img.shields.io/badge/shell-bash-4EAA25)

## 📖 Overview

This project is a resilient Bash automation tool designed to deploy static websites onto a Linux server. It abstracts the complexity of server configuration, dependency management, and file deployment into a single command.

The script is **OS-agnostic**, automatically detecting the underlying Linux distribution (Ubuntu/Debian or CentOS/RHEL) to use the appropriate package managers and service names.

## 🏗 Architecture

![Deployment Architecture Diagram]($PWD/architecture.png)

The automation workflow follows these steps:
1.  **Environment Check:** Validates OS type and user permissions.
2.  **Dependency Resolution:** Installs Apache, `wget`, `unzip`, and `curl` if missing.
3.  **Input Validation:** Verifies the validity and reachability of the source ZIP URL.
4.  **Deployment:** Downloads content, manages temporary storage, and deploys to `/var/www/html`.
5.  **Security & Cleanup:** Sets correct file ownership/permissions and performs garbage collection on exit.

## ✨ Key Features

* **🛡 Strict Error Handling:** Uses `set -euo pipefail` to ensure the script fails fast and safely upon encountering any error, preventing partial (broken) deployments.
* **🐧 Multi-OS Support:** Logic to handle package management differences between `apt` (Debian/Ubuntu) and `yum` (RHEL/CentOS).
* **🧹 Automatic Cleanup:** Implements `trap` functions to ensure temporary files are removed whether the script succeeds or crashes.
* **🔒 Security Compliance:** Enforces correct ownership (`www-data` or `apache`) and permissions (`755`) on web root files.
* **⚡ Idempotency:** Checks for existing packages and services before attempting installation to save time and resources.

## ⚙️ Prerequisites

* A Linux environment (Ubuntu, Debian, CentOS, or RHEL).
* `sudo` privileges (required to install packages and modify `/var/www/html`).
* Internet access for downloading packages and the source ZIP file.

## 🚀 Usage

### 1. Clone the Repository
```bash
git clone https://github.com/michaeltemitope/bash-static-web-setup.git
cd bash-static-web-setup/

### 2. Make the Script Executable

chmod +x deploy_static_website.sh

### 3. Run the Deployment

Pass the URL of your static website's ZIP file as an argument:

sudo ./deploy_static_website.sh [https://www.free-css.com/assets/files/free-css-templates/download/page254/photogenic.zip](https://www.free-css.com/assets/files/free-css-templates/download/page254/photogenic.zip)

Note: The URL must start with http:// or https:// and end with .zip

🧪 Testing
To verify the deployment, open your browser and navigate to your server's IP address or localhost:

http://localhost/