#!/bin/bash

# Enable strict error handling
set -euo pipefail
IFS=$'\n\t'

# This script downloads a zip file containing web content and deploys it to an Apache web server
# Usage: ./script.sh <zip_file_url>
# The script will:
# 1. Install Apache web server if not present
# 2. Install required utilities (wget, unzip) if not present  
# 3. Download and extract the zip file
# 4. Deploy the contents to Apache's web root
# 5. Clean up temporary files

# Constants
readonly APACHE_ROOT="/var/www/html"
readonly DOWNLOAD_FILE="download.zip"
readonly REQUIRED_PACKAGES=("curl" "wget" "unzip")

# Error handling function
handle_error() {
    local error_message="$1"
    local exit_code="${2:-1}"
    echo "ERROR: $error_message" >&2
    cleanup
    exit "$exit_code"
}

# Cleanup function
cleanup() {
    echo "Performing cleanup..."
    [[ -d "${temp_dir:-}" ]] && rm -rf "$temp_dir"
    [[ -f "$DOWNLOAD_FILE" ]] && rm -f "$DOWNLOAD_FILE"
}

# URL validation function
validate_url() {
    local url="$1"
    # Check if URL is well-formed and ends with .zip
    if ! [[ "$url" =~ ^https?:// ]] || ! [[ "$url" =~ \.zip$ ]]; then
        handle_error "Invalid URL format. URL must start with http:// or https:// and end with .zip"
    fi
    
    # Check if URL is accessible
    if ! curl --output /dev/null --silent --head --fail "$url"; then
        handle_error "URL is not accessible"
    fi
}

# Function to install required packages
install_package() {
    local package="$1"
    echo "Installing $package..."
    if [[ -f /etc/debian_version ]] && [[ "$package" == "${REQUIRED_PACKAGES[0]}" ]]; then
        sudo "$PKG_MANAGER" update
    fi
    sudo "$PKG_MANAGER" install -y "$package" || handle_error "Failed to install $package"
}

# Function to check and install required packages
check_required_packages() {
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! command -v "$package" &> /dev/null; then
            install_package "$package"
        fi
    done
}

# Function to setup and configure Apache
setup_apache() {
    # Install Apache if not present
    if ! command -v "$APACHE_SERVICE" &> /dev/null; then
        echo "Installing Apache HTTP Server..."
        sudo "$PKG_MANAGER" install -y "$APACHE_PKG" || handle_error "Failed to install Apache"
    fi

    # Start and enable Apache service if needed
    if ! systemctl is-active --quiet "$APACHE_SERVICE" || ! systemctl is-enabled --quiet "$APACHE_SERVICE"; then
        echo "Configuring Apache service..."
        sudo systemctl start "$APACHE_SERVICE" || handle_error "Failed to start Apache service"
        sudo systemctl enable "$APACHE_SERVICE" || handle_error "Failed to enable Apache service"
    fi

    # Create web root directory if it doesn't exist
    sudo mkdir -p "$APACHE_ROOT"
}

# Function to deploy files
deploy_files() {
    local temp_dir="$1"
    local extracted_dir
    
    extracted_dir="$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    local source_dir="${extracted_dir:+${extracted_dir}/}${extracted_dir:-.}"
    sudo cp -r "${source_dir}"* "$APACHE_ROOT/" || handle_error "Failed to copy files to Apache root directory"

    sudo chown -R "$APACHE_USER:$APACHE_GROUP" "$APACHE_ROOT/" || handle_error "Failed to set ownership of web files"
    sudo chmod -R 755 "$APACHE_ROOT/" || handle_error "Failed to set permissions on web files"
}

# Set up trap for script termination
trap cleanup EXIT INT TERM

# Validate command line arguments
if [[ $# -ne 1 ]]; then
    handle_error "Script requires exactly one argument\nUsage: $0 <zip_file_url>"
fi

# Validate the provided URL
readonly zip_url="$1"
validate_url "$zip_url"

# Detect Linux distribution and set package manager and Apache variables
declare PKG_MANAGER APACHE_PKG APACHE_SERVICE APACHE_USER APACHE_GROUP

if [[ -f /etc/redhat-release ]]; then
    # RedHat/CentOS
    PKG_MANAGER="yum"
    APACHE_PKG="httpd"
    APACHE_SERVICE="httpd"
    APACHE_USER="apache"
    APACHE_GROUP="apache"
elif [[ -f /etc/debian_version ]]; then
    # Debian/Ubuntu
    PKG_MANAGER="apt-get"
    APACHE_PKG="apache2"
    APACHE_SERVICE="apache2"
    APACHE_USER="www-data"
    APACHE_GROUP="www-data"
else
    handle_error "Unsupported Linux distribution"
fi

# Install required packages
check_required_packages

# Setup Apache
setup_apache

# Download zip file from provided URL
echo "Downloading zip file from: $zip_url"
wget "$zip_url" -O "$DOWNLOAD_FILE" || handle_error "Failed to download the zip file"

echo "Extracting zip file..."
# Create a temporary directory for extraction
readonly temp_dir="$(mktemp -d)" || handle_error "Failed to create temporary directory"
unzip -o "$DOWNLOAD_FILE" -d "$temp_dir" || handle_error "Failed to extract the zip file"

echo "Copying files to Apache root directory..."
deploy_files "$temp_dir"

echo "Deployment completed successfully"
