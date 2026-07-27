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

update_system_packages() {

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


    if [[ -z "$TIMEZONE" ]]; then

        log_error "Timezone not configured."

        return 1

    fi


    log_info "Setting timezone to ${TIMEZONE}"


    timedatectl set-timezone "$TIMEZONE"


    log_success "Timezone set to ${TIMEZONE}"

}

################################################################################
# Install Base Packages
################################################################################

install_system_packages() {


    step "install_system_packages"


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

configure_system_hardware_monitoring()


    step "Configuring hardware monitoring"


    if command_exists sensors-detect; then

        run_command \
            "Detecting hardware sensors" \
            sensors-detect \
            --auto

        run_command \
            "Testing sensor output" \
            sensors

        log_success "Hardware sensor detection completed."

    else

        log_warn "sensors-detect not available."

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

install_system() {

    step "Starting System Preparation"


    require_root

    check_os

    check_internet


    update_system_packages


    configure_hostname

    configure_timezone

    configure_time_sync

    configure_updates

    configure_system_hardware_monitoring


    system_summary


    log_success "System Preparation completed."

}
