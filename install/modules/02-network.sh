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
    resolvectl status || true

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


    if ip addr | grep -q "${IP}"; then

        log_success "Configured IP is active."

    else

        log_warn "Configured IP is not currently assigned."

    fi

}


################################################################################
# Configure Hosts File
################################################################################

configure_hosts() {


    step "Updating hosts file"


    local HOSTNAME

    HOSTNAME=$(config_get hostname)


    if grep -q "${HOSTNAME}" /etc/hosts; then

        log_success "Hostname already exists in hosts file."

    else

        run_command \
            "Adding hostname entry" \
            bash -c "echo '127.0.1.1 ${HOSTNAME}' >> /etc/hosts"

    fi

}


################################################################################
# Enable IPv4 Forwarding
################################################################################

enable_ip_forwarding() {


    step "Enabling IPv4 forwarding"


    cat >/etc/sysctl.d/99-netcore.conf <<EOF
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

check_dns() {


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

    step "Starting Network Preparation"

    require_root
    check_os
    check_internet

    install_network_packages

    validate_network_configuration
    update_hosts_file
    enable_ip_forwarding
    test_gateway
    test_dns
    show_network_information

    log_success "Network Preparation completed."
}


run_network_module
