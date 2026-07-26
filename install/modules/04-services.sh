#!/usr/bin/env bash
#
# ==============================================================================
# NetCore Services Module
# ==============================================================================
# Installs common utilities and prepares the system for additional services.
#
# ==============================================================================

set -Eeuo pipefail

################################################################################
# Install Base Packages
################################################################################

install_base_packages() {

    step "Installing Base Utilities"

    local PACKAGES=(
        curl
        wget
        git
        vim
        nano
        htop
        tree
        jq
        yq
        unzip
        zip
        rsync
    )

    for PACKAGE in "${PACKAGES[@]}"; do

        install_package "$PACKAGE"

    done

}

################################################################################
# Install Networking Packages
################################################################################

install_network_packages() {

    step "Installing Networking Utilities"

    local PACKAGES=(
        dnsutils
        net-tools
        nfs-common
        avahi-daemon
        iputils-ping
        traceroute
    )

    for PACKAGE in "${PACKAGES[@]}"; do

        install_package "$PACKAGE"

    done

}

################################################################################
# Create NetCore Directories
################################################################################

create_netcore_directories() {

    step "Creating NetCore Directory Structure"

    local DIRECTORIES=(
        /opt/netcore
        /opt/netcore/backups
        /opt/netcore/scripts
        /opt/netcore/downloads
        /opt/netcore/logs
        /opt/netcore/cache
        /opt/netcore/temp
        /opt/netcore/config
    )

    chmod 755 /opt/netcore

    chmod -R 755 /opt/netcore

    for DIR in "${DIRECTORIES[@]}"; do

        create_directory "$DIR"

    done

}

################################################################################
# Service Health Checks
################################################################################

check_core_services() {

    step "Checking Core Services"

    local PASSED=0
    local FAILED=0
    local SERVICES=(
        ssh
        fail2ban
        tailscaled
        cockpit.socket
    )


    for SERVICE in "${SERVICES[@]}"; do


        if service_exists "$SERVICE"; then


            if is_service_active "$SERVICE"; then

                log_success "$SERVICE is running"

                PASSED=$((PASSED + 1))

            else

                log_warn "$SERVICE is installed but not running"

                FAILED=$((FAILED + 1))

            fi


        else

            log_warn "$SERVICE is not installed"

            FAILED=$((FAILED + 1))

        fi


    done

    echo

    log_info "Service Check Summary"

    log_info "Running: ${PASSED}"

    log_info "Issues: ${FAILED}"

}
