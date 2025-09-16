#!/bin/bash

set -ex

env|sort|uniq

# LUKS Integration Test Script for Cosmian PKCS#11 module
# This script tests the complete LUKS integration workflow as documented
# in documentation/docs/pkcs11/luks.md

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Cleanup function
cleanup() {
    log "Cleaning up test resources..."

    # Unmount and close LUKS if mounted
    if mountpoint -q /mnt/test_luks 2>/dev/null; then
        sudo umount /mnt/test_luks || true
    fi

    # Close LUKS device if open
    if [ -e /dev/mapper/test_luks ]; then
        sudo cryptsetup close test_luks || true
    fi

    # Remove test file
    if [ -f /tmp/test_luks_file ]; then
        sudo rm -f /tmp/test_luks_file || true
    fi

    # Remove mount point
    if [ -d /mnt/test_luks ]; then
        sudo rmdir /mnt/test_luks || true
    fi

    # Stop docker containers
    docker compose down || true

    # Remove temporary files
    rm -f /tmp/private_key.pem /tmp/cert.pem /tmp/certificate.p12 || true
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Check if we're running on Ubuntu 24.04
check_ubuntu_version() {
    log "Checking Ubuntu version..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" && "$VERSION_ID" == "24.04" ]]; then
            log "Running on Ubuntu 24.04 - proceeding with test"
        else
            warning "Not running on Ubuntu 24.04 (detected: $ID $VERSION_ID)"
            warning "This test is designed for Ubuntu 24.04, some steps may fail"
        fi
    else
        warning "Cannot determine OS version"
    fi
}

# Install required packages
check_packages() {
    log "Verifying package installation..."
    which p11-kit || { error "p11-kit not installed"; exit 1; }
    which cryptsetup || { error "cryptsetup not installed"; exit 1; }
    which openssl || { error "openssl not installed"; exit 1; }
}

# Setup PKCS#11 configuration
setup_pkcs11_config() {
    log "Setting up PKCS#11 configuration..."

    # Create PKCS#11 directories
    sudo mkdir -p /etc/pkcs11/modules

    # Create main PKCS#11 configuration
    sudo tee /etc/pkcs11/pkcs11.conf > /dev/null <<EOF
# This setting controls whether to load user configuration from the
# ~/.config/pkcs11 directory. Possible values:
#    none: No user configuration
#    merge: Merge the user config over the system configuration (default)
#    only: Only user configuration, ignore system configuration
user-config: merge
EOF

    # Check if libcosmian_pkcs11.so exists
    if [ ! -f "./libcosmian_pkcs11.so" ]; then
        error "libcosmian_pkcs11.so not found in current directory"
        error "Please ensure the PKCS#11 module is built before running this test"
        exit 1
    fi

    # Copy the PKCS#11 module
    sudo cp ./libcosmian_pkcs11.so /usr/local/lib/
    sudo chmod 755 /usr/local/lib/libcosmian_pkcs11.so
    sudo chown -R "$USER": /var/log

    # Create module configuration
    sudo tee /etc/pkcs11/modules/cosmian_pkcs11.module > /dev/null <<EOF
# Cosmian KMS PKCS#11 module
module: /usr/local/lib/libcosmian_pkcs11.so
EOF

    log "PKCS#11 configuration completed"
}

# Setup KMS configuration
setup_kms_config() {
    log "Setting up KMS configuration..."

    # Create cosmian config directory
    sudo mkdir -p /etc/cosmian

    # Create KMS configuration for local testing
    sudo tee /etc/cosmian/cosmian.toml > /dev/null <<EOF
[kms_config.http_config]
server_url = "http://localhost:9998"
EOF

    log "KMS configuration completed"
}

# Test PKCS#11 module loading
test_pkcs11_module() {
    log "Testing PKCS#11 module loading..."

    # List modules and check if cosmian module is loaded
    if p11-kit list-modules | grep -q "cosmian_pkcs11"; then
        log "Cosmian PKCS#11 module loaded successfully"
        p11-kit list-modules | grep -A 15 "cosmian_pkcs11"
    else
        error "Cosmian PKCS#11 module not found in p11-kit list"
        p11-kit list-modules
        exit 1
    fi
}

# Generate RSA key pair and import to KMS
generate_and_import_key() {
    log "Generating RSA key pair and importing to KMS..."

    # Generate private key
    openssl genpkey -algorithm RSA -out /tmp/private_key.pem -pkeyopt rsa_keygen_bits:2048

    # Create self-signed certificate
    openssl req -new -x509 -key /tmp/private_key.pem -out /tmp/cert.pem -days 365 -subj "/C=US/ST=Test/L=Test/O=Cosmian/CN=test"

    # Convert to PKCS12
    openssl pkcs12 -export -out /tmp/certificate.p12 -inkey /tmp/private_key.pem -in /tmp/cert.pem -passout pass:testpass

    # Import to KMS using the CLI
    COSMIAN="cargo run --bin cosmian --"
    export COSMIAN_KMS_CLI_FORMAT=json

    log "Importing certificate to KMS..."
    key_id=$($COSMIAN kms certificates import -f pkcs12 -t disk-encryption /tmp/certificate.p12 -p testpass | jq -r .unique_identifier)

    if [ -z "$key_id" ] || [ "$key_id" == "null" ]; then
        error "Failed to import certificate to KMS"
        exit 1
    fi

    log "Certificate imported with key ID: $key_id"
    echo "$key_id" > /tmp/key_id.txt
}

# Create test LUKS partition
create_luks_partition() {
    log "Creating test LUKS partition..."

    # Create a 100MB file for testing
    fallocate -l 100M /tmp/test_luks_file

    # Create LUKS partition with a test passphrase
    echo "testpassphrase" | sudo cryptsetup luksFormat --type luks2 --key-slot 0 /tmp/test_luks_file -

    log "LUKS partition created successfully"
}

# Enroll LUKS partition with KMS
enroll_luks_with_kms() {
    log "Enrolling LUKS partition with Cosmian KMS..."

    # Set environment variables for PKCS#11 module
    export COSMIAN_PKCS11_LOGGING_LEVEL=debug
    export COSMIAN_PKCS11_DISK_ENCRYPTION_TAG=disk-encryption

    # Enroll with systemd-cryptenroll
    echo "testpassphrase" | sudo systemd-cryptenroll --pkcs11-token-uri=pkcs11:token=Cosmian-KMS /tmp/test_luks_file

    log "LUKS partition enrolled with KMS successfully"
}

# Test LUKS unlocking with KMS
test_luks_unlocking() {
    log "Testing LUKS unlocking with KMS..."

    # Set environment variables
    export COSMIAN_PKCS11_LOGGING_LEVEL=debug
    export COSMIAN_PKCS11_DISK_ENCRYPTION_TAG=disk-encryption

    # Try to unlock using token
    sudo cryptsetup open --type luks2 --token-id=0 --token-only /tmp/test_luks_file test_luks

    if [ ! -e /dev/mapper/test_luks ]; then
        error "Failed to unlock LUKS partition with KMS token"
        exit 1
    fi

    log "LUKS partition unlocked successfully with KMS token"
}

# Test filesystem operations
test_filesystem_operations() {
    log "Testing filesystem operations on unlocked LUKS partition..."

    # Format the partition
    sudo mkfs.ext4 /dev/mapper/test_luks

    # Create mount point and mount
    sudo mkdir -p /mnt/test_luks
    sudo mount /dev/mapper/test_luks /mnt/test_luks

    # Test write/read operations
    echo "Test data for LUKS integration" | sudo tee /mnt/test_luks/test_file.txt

    # Verify the file content
    test_content=$(sudo cat /mnt/test_luks/test_file.txt)
    if [ "$test_content" != "Test data for LUKS integration" ]; then
        error "Filesystem read/write test failed"
        exit 1
    fi

    log "Filesystem operations test passed"
}

# Verify LUKS configuration
verify_luks_config() {
    log "Verifying LUKS configuration..."

    # Dump LUKS header to verify token enrollment
    sudo cryptsetup luksDump /tmp/test_luks_file | sudo tee /tmp/luks_dump.txt > /dev/null

    if grep -q "systemd-pkcs11" /tmp/luks_dump.txt && grep -q "pkcs11-uri: pkcs11:token=Cosmian-KMS" /tmp/luks_dump.txt; then
        log "LUKS token configuration verified successfully"
    else
        error "LUKS token configuration verification failed"
        cat /tmp/luks_dump.txt
        exit 1
    fi
}

# Main test execution
main() {
    log "Starting LUKS integration test for Cosmian PKCS#11 module"
    log "=================================================="

    check_ubuntu_version
    check_packages
    setup_pkcs11_config
    setup_kms_config
    test_pkcs11_module
    generate_and_import_key
    create_luks_partition
    enroll_luks_with_kms
    verify_luks_config
    test_luks_unlocking
    test_filesystem_operations

    log "=================================================="
    log "All LUKS integration tests passed successfully!"
    log "The libcosmian_pkcs11.so module is working correctly with LUKS"
}

# Run main function
main "$@"
