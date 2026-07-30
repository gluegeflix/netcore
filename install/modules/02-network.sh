#!/usr/bin/env bash
#
# ==============================================================================
# NetCore Network Preparation Module
# ==============================================================================
# Prepares Ubuntu networking for NetCore services.
#
# Loaded by:
#   netcore.sh
#
# ==============================================================================


set -Eeuo pipefail


################################################################################
# Module Information
################################################################################

MODULE_NAME="Network Preparation"


################################################################################
# Install Network Tools
################################################################################

install_network_packages() {


    step "Installing network utilities"


    local PACKAGES=(

        iproute2

        net-tools

        dnsutils

        traceroute

        tcpdump

    )


    for PACKAGE in "${PACKAGES[@]}"
    do

        install_package "$PACKAGE"

    done

}


################################################################################
# Network Information
################################################################################

show_current_network() {


    step "Current network information"


    echo

    echo "Interfaces:"
    ip addr show


    echo

    echo "Routes:"
    ip route


    echo

    echo "DNS:"
    SYSTEMD_PAGER=cat resolvectl status --no-pager || true

}


################################################################################
# Validate Configuration
################################################################################

validate_network_config() {


    step "Validating NetCore network configuration"


    local IP

    local GATEWAY

    local SUBNET


    IP=$(config_get network.ip)

    GATEWAY=$(config_get network.gateway)

    SUBNET=$(config_get network.subnet)


    log_info "Configured IP: ${IP}"

    log_info "Configured Gateway: ${GATEWAY}"

    log_info "Configured Subnet: ${SUBNET}"


    local ADDRESS
    local IP_ACTIVE=false

    while read -r ADDRESS; do

        if [[ "${ADDRESS%/*}" == "$IP" ]]; then
            IP_ACTIVE=true
            break
        fi

    done < <(ip -4 -o addr show | awk '{print $4}')

    if [[ "$IP_ACTIVE" == true ]]; then
        log_success "Configured IP is active."
    else
        log_warn "Configured IP is not currently assigned."
    fi

}


################################################################################
# Configure Hosts File
################################################################################

configure_network_hosts() {

    step "Updating hosts file"

    local HOSTNAME
    HOSTNAME=$(config_get hostname)

    if grep -qw "$HOSTNAME" /etc/hosts; then
        log_success "Hostname already exists in hosts file."
        return 0
    fi

    backup_file /etc/hosts /opt/netcore/backups

    append_file /etc/hosts 644 root:root <<EOF
127.0.1.1 ${HOSTNAME}
EOF

}
################################################################################
# Enable IPv4 Forwarding
################################################################################
enable_ip_forwarding() {

    step "Enabling IP forwarding"

    backup_file \
        /etc/sysctl.d/99-netcore.conf \
        /opt/netcore/backups

    write_file \
        /etc/sysctl.d/99-netcore.conf \
        644 \
        root:root <<EOF
# NetCore networking configuration
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
EOF

    run_command \
        "Applying kernel network settings" \
        sysctl --system

    log_success "IP forwarding enabled."

}

################################################################################
# DNS Check
################################################################################

check_network_dns() {


    step "Testing DNS"


    if command_exists dig; then


        if dig google.com >/dev/null 2>&1; then

            log_success "DNS resolution working."

        else

            log_warn "DNS resolution failed."

        fi


    else

        log_warn "dig not available."

    fi

}


################################################################################
# Gateway Test
################################################################################

test_gateway() {


    step "Testing gateway connectivity"


    local GATEWAY

    GATEWAY=$(config_get network.gateway)


    if ping -c 2 "$GATEWAY" >/dev/null 2>&1; then

        log_success "Gateway reachable."

    else

        log_warn "Gateway unreachable."

    fi

}


################################################################################
# Network Summary
################################################################################

network_summary() {


    echo

    echo "=============================================="

    echo "NetCore Network Summary"

    echo "=============================================="

    echo


    echo "Hostname:"
    hostname


    echo

    echo "IPv4 Addresses:"
    ip -4 addr show | grep inet || true


    echo

    echo "Default Route:"
    ip route | grep default || true


    echo

    echo "Forwarding:"

    sysctl net.ipv4.ip_forward


    echo

}


################################################################################
# Module Entry Point
################################################################################

install_network() {

    module_start "Network Preparation"

    require_root

    check_os

    install_network_packages

    validate_network_config

    configure_network_hosts

    enable_ip_forwarding

    test_gateway

    check_network_dns

    show_current_network

    network_summary

    module_finish "Network Preparation"

}
