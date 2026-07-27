#!/usr/bin/env bash
#
# ==============================================================================
# NetCore Security Baseline Module
# ==============================================================================
# Applies basic security configuration for NetCore servers.
#
# Loaded by:
#   netcore.sh
#
# ==============================================================================


set -Eeuo pipefail


################################################################################
# Module Information
################################################################################

MODULE_NAME="Security Baseline"


################################################################################
# Install Security Packages
################################################################################

install_security_packages() {

    step "Installing security packages"


    local PACKAGES=(

        ufw

        fail2ban

        unattended-upgrades

        apt-listchanges

    )


    for PACKAGE in "${PACKAGES[@]}"
    do

        install_package "$PACKAGE"

    done

}


################################################################################
# Configure Firewall
################################################################################

configure_firewall() {

    step "Configuring firewall"


    log_info "Allowing SSH access"


    run_command \
        "Allow SSH through firewall" \
        ufw allow ssh


    run_command \
        "Enable firewall" \
        ufw --force enable


    log_success "Firewall enabled."

}


################################################################################
# Configure Fail2Ban
################################################################################

configure_fail2ban() {

    step "Configuring Fail2Ban"


    local FAIL2BAN_DIR="/etc/fail2ban"

    local JAIL_FILE="${FAIL2BAN_DIR}/jail.local"


    #
    # Ensure Fail2Ban configuration directory exists
    #
    create_directory "$FAIL2BAN_DIR"


    if [[ -f "$JAIL_FILE" ]]; then

        log_success "Fail2Ban configuration already exists."

    else


        cat > "$JAIL_FILE" <<EOF
[DEFAULT]

bantime = 1h

findtime = 10m

maxretry = 5


[sshd]

enabled = true

EOF


        log_success "Created Fail2Ban configuration."

    fi


    systemctl daemon-reload


    enable_service fail2ban

}


################################################################################
# Configure Automatic Security Updates
################################################################################

configure_auto_updates() {

    step "Configuring automatic security updates"


    cat >/etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";

APT::Periodic::Unattended-Upgrade "1";

EOF


    log_success "Automatic updates enabled."

}


################################################################################
# Kernel Hardening
################################################################################

configure_kernel_security() {

    step "Applying kernel security settings"


    cat >/etc/sysctl.d/99-netcore-security.conf <<EOF
#
# NetCore security baseline
#

kernel.randomize_va_space=2

net.ipv4.conf.all.rp_filter=1

net.ipv4.conf.default.rp_filter=1

net.ipv4.icmp_echo_ignore_broadcasts=1

net.ipv4.conf.all.accept_redirects=0

net.ipv4.conf.default.accept_redirects=0

net.ipv4.conf.all.send_redirects=0

net.ipv4.conf.default.send_redirects=0

EOF


    run_command \
        "Applying security sysctl settings" \
        sysctl --system

}


################################################################################
# File Permission Checks
################################################################################

secure_permissions() {

    step "Checking sensitive file permissions"


    if [[ -f /etc/shadow ]]; then

        chmod 640 /etc/shadow

        log_success "Protected /etc/shadow"

    fi


    if [[ -f /etc/gshadow ]]; then

        chmod 640 /etc/gshadow

        log_success "Protected /etc/gshadow"

    fi

}


################################################################################
# Disable Unused Services
################################################################################

disable_unused_services() {

    step "Checking unnecessary services"


    local SERVICES=(

        avahi-daemon

        cups

    )


    for SERVICE in "${SERVICES[@]}"
    do

        if systemctl list-unit-files | grep -q "^${SERVICE}"; then


            systemctl disable --now "$SERVICE" 2>/dev/null || true


            log_success "Disabled ${SERVICE}"

        fi

    done

}


################################################################################
# Security Summary
################################################################################

security_summary() {


    echo

    echo "=============================================="

    echo "NetCore Security Summary"

    echo "=============================================="

    echo


    echo "Firewall Status:"
    ufw status || true


    echo

    echo "Fail2Ban Status:"
    systemctl status fail2ban --no-pager -l | head -20 || true


    echo

    echo "Listening Ports:"
    ss -tulpn


    echo

}


################################################################################
# Module Entry Point
################################################################################

install_security() {


    step "Starting Security Preparation"

    require_root

    check_os


    install_security_packages


    configure_firewall


    configure_fail2ban


    configure_auto_updates


    configure_kernel_security


    secure_permissions


    disable_unused_services


    security_summary


    log_success "Security Preparation completed."

}



