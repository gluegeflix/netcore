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

################################################################################
# System Readiness Checks
################################################################################

check_system_readiness() {

    step "System Readiness Check"

    local PASSED=0
    local FAILED=0


    #
    # Hostname
    #
    local HOSTNAME

    HOSTNAME=$(hostname)


    if [[ -n "$HOSTNAME" ]]; then

        log_success "Hostname: $HOSTNAME"

        PASSED=$((PASSED + 1))

    else

        log_warn "Hostname not configured"

        FAILED=$((FAILED + 1))

    fi



    #
    # Timezone
    #
    local TIMEZONE

    TIMEZONE=$(timedatectl show --property=Timezone --value)


    if [[ -n "$TIMEZONE" ]]; then

        log_success "Timezone: $TIMEZONE"

        PASSED=$((PASSED + 1))

    else

        log_warn "Timezone not configured"

        FAILED=$((FAILED + 1))

    fi



    #
    # Time Sync
    #
    if timedatectl status | grep -q "System clock synchronized: yes"; then

        log_success "Time synchronization active"

        PASSED=$((PASSED + 1))

    else

        log_warn "Time synchronization inactive"

        FAILED=$((FAILED + 1))

    fi



    #
    # Disk Space
    #
    local DISK_USAGE

    DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')


    if [[ "$DISK_USAGE" -lt 90 ]]; then

        log_success "Disk usage: ${DISK_USAGE}%"

        PASSED=$((PASSED + 1))

    else

        log_warn "Disk usage high: ${DISK_USAGE}%"

        FAILED=$((FAILED + 1))

    fi



    #
    # Memory
    #
    local MEMORY_AVAILABLE

    MEMORY_AVAILABLE=$(free -m | awk '/Mem:/ {print $7}')


    if [[ "$MEMORY_AVAILABLE" -gt 256 ]]; then

        log_success "Memory available: ${MEMORY_AVAILABLE}MB"

        PASSED=$((PASSED + 1))

    else

        log_warn "Low memory: ${MEMORY_AVAILABLE}MB"

        FAILED=$((FAILED + 1))

    fi



    #
    # Reboot Required
    #
    if [[ -f /var/run/reboot-required ]]; then

        log_warn "System reboot required"

        FAILED=$((FAILED + 1))

    else

        log_success "No reboot required"

        PASSED=$((PASSED + 1))

    fi



    echo

    log_info "System Readiness Summary"

    log_info "Passed: ${PASSED}"

    log_info "Issues: ${FAILED}"

}


################################################################################
# Module Runner
################################################################################

install_services() {

    step "NetCore Services Module"

    local ERRORS=0


    if ! install_base_packages; then

        log_error "Base package installation failed."

        ERRORS=$((ERRORS + 1))

    fi


    if ! install_network_packages; then

        log_error "Network package installation failed."

        ERRORS=$((ERRORS + 1))

    fi


    if ! create_netcore_directories; then

        log_error "Directory creation failed."

        ERRORS=$((ERRORS + 1))

    fi


    if ! check_core_services; then

        log_warn "Core service checks reported issues."

    fi


    if ! check_system_readiness; then

        log_warn "System readiness checks reported issues."

    fi


    echo


    if [[ "$ERRORS" -eq 0 ]]; then

        log_success "Services module completed successfully."

        return 0

    else

        log_error "Services module completed with errors."

        return 1

    fi

}
