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
