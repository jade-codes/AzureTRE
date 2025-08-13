#!/bin/bash

# Software Engineering VM Image Dependencies Download Script
# This script downloads required software and uploads to Azure Storage Account

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check required environment variables
check_env_vars() {
    print_info "Checking required environment variables..."

    if [[ -z "$TRE_ID" ]]; then
        print_error "TRE_ID environment variable is required"
        exit 1
    fi

    print_success "Environment variables check passed"
}

# Get local public IP address
get_local_ip() {
    print_info "Getting local public IP address..."
    LOCAL_IP=$(curl -s https://api.ipify.org)
    if [[ -z "$LOCAL_IP" ]]; then
        print_error "Failed to get local IP address"
        exit 1
    fi
    print_success "Local IP address: $LOCAL_IP"
}

# Get storage account name
get_storage_account() {
    print_info "Getting storage account name..."
    STORAGE_ACCOUNT_NAME="stsft${TRE_ID}"
    print_success "Storage account name: $STORAGE_ACCOUNT_NAME"
}

# Get storage account resource group name
get_storage_account_resource_group_name() {
    print_info "Getting storage account resource group name..."
    RESOURCE_GROUP_NAME="rg-${TRE_ID}"
    print_success "Storage account resource group name: $RESOURCE_GROUP_NAME"
}

# Add firewall rule to storage account
add_firewall_rule() {
    print_info "Adding firewall rule for local IP to storage account..."

    az storage account network-rule add \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --ip-address "$LOCAL_IP" \
        --output none

    print_success "Firewall rule added successfully"

    # Wait a moment for the rule to take effect
    print_info "Waiting for firewall rule to take effect..."
    sleep 10
}

# Remove firewall rule from storage account
remove_firewall_rule() {
    print_info "Removing firewall rule for local IP from storage account..."


    az storage account network-rule remove \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --ip-address "$LOCAL_IP" \
        --output none

    print_success "Firewall rule removed successfully"
}

# Create temporary directory for downloads
create_temp_dir() {
    TEMP_DIR=$(mktemp -d)
    print_info "Created temporary directory: $TEMP_DIR"

    # Ensure cleanup on exit
    trap 'print_info "Cleaning up temporary directory..."; rm -rf "$TEMP_DIR"' EXIT
}

# Download a file with retry logic
download_file() {
    local url=$1
    local filename=$2
    local max_retries=3
    local retry_count=0

    while [[ $retry_count -lt $max_retries ]]; do
        print_info "Downloading $filename (attempt $((retry_count + 1))/$max_retries)..."

        if wget -O "$TEMP_DIR/$filename" "$url" --progress=bar:force 2>&1; then
            print_success "Downloaded $filename successfully"
            return 0
        else
            retry_count=$((retry_count + 1))
            print_warning "Download failed for $filename (attempt $retry_count/$max_retries)"

            if [[ $retry_count -lt $max_retries ]]; then
                print_info "Retrying in 5 seconds..."
                sleep 5
            fi
        fi
    done

    print_error "Failed to download $filename after $max_retries attempts"
    return 1
}

# Upload file to storage account
upload_file() {
    local filename=$1
    local destination_path=$2

    print_info "Uploading $filename to storage account..."

    az storage blob upload \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --container-name "installers" \
        --name "softwareeng/$destination_path" \
        --file "$TEMP_DIR/$filename" \
        --auth-mode login \
        --overwrite \
        --output none

    print_success "Uploaded $filename to softwareeng/$destination_path"
}

# Download all dependencies
download_dependencies() {
    print_info "Starting download of all dependencies..."

    # Define downloads with URL, filename, and destination path
    declare -A downloads=(
        ["https://update.code.visualstudio.com/latest/win32-x64/stable"]="vscode_installer.exe:vscode_installer.exe"
        ["https://github.com/git-for-windows/git/releases/download/v2.50.1.windows.1/Git-2.50.1-64-bit.exe"]="git_installer.exe:git_installer.exe"
        ["https://github.com/containers/podman/releases/download/v5.5.2/podman-5.5.2-setup.exe"]="podman_installer.exe:podman_installer.exe"
        ["https://github.com/containers/podman-machine-wsl-os/releases/download/v20250206061445/5.3-rootfs-amd64.tar.zst"]="5.3-rootfs-amd64.tar.zst:5.3-rootfs-amd64.tar.zst"
    )

    local failed_downloads=()

    for url in "${!downloads[@]}"; do
        IFS=':' read -r filename destination <<< "${downloads[$url]}"

        if download_file "$url" "$filename"; then
            if upload_file "$filename" "$destination"; then
                print_success "Successfully processed $filename"
            else
                print_error "Failed to upload $filename"
                failed_downloads+=("$filename")
            fi
        else
            print_error "Failed to download $filename"
            failed_downloads+=("$filename")
        fi
    done

    if [[ ${#failed_downloads[@]} -gt 0 ]]; then
        print_error "The following files failed to process:"
        for file in "${failed_downloads[@]}"; do
            echo "  - $file"
        done
        return 1
    else
        print_success "All dependencies downloaded and uploaded successfully!"
        return 0
    fi
}

# Main function
main() {
    print_info "Starting Software Engineering VM Image Dependencies Download Script"
    print_info "=============================================================="

    # Check prerequisites
    check_env_vars
    get_local_ip
    get_storage_account
    get_storage_account_resource_group_name
    create_temp_dir

    # Add firewall rule
    add_firewall_rule

    # Ensure firewall rule is removed on exit (even if script fails)
    trap 'remove_firewall_rule; print_info "Cleaning up temporary directory..."; rm -rf "$TEMP_DIR"' EXIT

    # Download and upload dependencies
    if download_dependencies; then
        print_success "Script completed successfully!"
        exit 0
    else
        print_error "Script completed with errors!"
        exit 1
    fi
}

# Check if required tools are installed
check_prerequisites() {
    local missing_tools=()

    if ! command -v az &> /dev/null; then
        missing_tools+=("azure-cli")
    fi

    if ! command -v wget &> /dev/null; then
        missing_tools+=("wget")
    fi

    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "The following required tools are missing:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        print_error "Please install the missing tools and try again."
        exit 1
    fi
}

# Run prerequisite checks and main function
check_prerequisites
main "$@"
