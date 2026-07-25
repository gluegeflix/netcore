#!/usr/bin/env bash
#
# ==============================================================================
# NetCore System Preparation Module
# ==============================================================================
# Prepares Ubuntu system for NetCore services.
#
# Loaded by:
#   netcore.sh
#
# ==============================================================================


set -Eeuo pipefail


################################################################################
# Module Information
################################################################################

MODULE_NAME="System Preparation"


################################################################################
# Update System
################################################################################

system_update() {

    step "Updating Ubuntu packages"


    run_command \
        "Updating package lists" \
        apt-get update


    run_command \
        "Upgrading installed packages" \
        apt-get upgrade -y

}


################################################################################
# Configure Hostname
################################################################################

configure_hostname() {

    local HOSTNAME

    HOSTNAME=$(config_get hostname)


    step "Configuring hostname"


    if [[ "$(hostname)" == "$HOSTNAME" ]]; then

        log_success "Hostname already set: ${HOSTNAME}"

    else

        run_command \
            "Setting hostname to ${HOSTNAME}" \
            hostnamectl set-hostname "$HOSTNAME"

    fi

}


################################################################################
# Configure Timezone
################################################################################

configure_timezone() {

    local TIMEZONE

    TIMEZONE=$(config_get timezone)


    step "Configuring timezone"


    CURRENT_TIMEZONE=$(timedatectl show \
        --property=Timezone \
        --value)


    if [[ "$CURRENT_TIMEZONE" == "$TIMEZONE" ]]; then

        log_success "Timezone already set: ${TIMEZONE}"

    else

        run_command \
            "Setting timezone to ${TIMEZONE}" \
            timedatectl set-timezone "$TIMEZONE"

    fi

}


################################################################################
# Install Base Packages
################################################################################

install_base_packages() {


    step "Installing base packages"


    local PACKAGES=(

        curl

        wget

        git

        nano

        vim

        unzip

        jq

        htop

        net-tools

        dnsutils

        ca-certificates

        gnupg

        lsb-release

        chrony

        smartmontools

        lm-sensors

        unattended-upgrades

    )


    for PACKAGE in "${PACKAGES[@]}"
    do

        install_package "$PACKAGE"

    done

}


################################################################################
# Configure Time Synchronization
################################################################################

configure_time_sync() {


    step "Configuring time synchronization"


    enable_service chrony

}


################################################################################
# Configure Automatic Updates
################################################################################

configure_updates() {


    step "Configuring unattended upgrades"


    if [[ -f /etc/apt/apt.conf.d/20auto-upgrades ]]; then

        log_success "Unattended upgrades already configured."

    else

        run_command \
            "Enable unattended upgrades" \
            dpkg-reconfigure \
            -plow \
            unattended-upgrades

    fi

}


################################################################################
# Hardware Monitoring
################################################################################

configure_hardware_monitoring() {


    step "Configuring hardware monitoring"


    if command_exists sensors-detect; then

        run_command \
            "Detecting hardware sensors" \
            sensors-detect \
            --auto

    else

        log_warn "lm-sensors unavailable."

    fi

}


################################################################################
# System Summary
################################################################################

system_summary() {


    echo

    echo "=============================================="

    echo "NetCore System Summary"

    echo "=============================================="

    echo


    echo "Hostname:"
    hostname


    echo

    echo "IP Addresses:"
    hostname -I


    echo

    echo "Kernel:"
    uname -r


    echo

    echo "CPU:"
    lscpu | grep "Model name" || true


    echo

    echo "Memory:"
    free -h


    echo

}


################################################################################
# Module Entry Point
################################################################################

run_system_module() {


    log_info "Starting ${MODULE_NAME}"


    check_os

    check_internet


    system_update


    configure_hostname


    configure_timezone


    install_base_packages


    configure_time_sync


    configure_updates


    configure_hardware_monitoring


    system_summary


    log_success "${MODULE_NAME} completed."

}


run_system_module
