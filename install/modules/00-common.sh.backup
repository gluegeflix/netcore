#!/usr/bin/env bash
#
# ==============================================================================
# NetCore Common Library
# ==============================================================================
# Shared helper functions used by every NetCore installer module.
#
# Author: NetCore Project
# License: MIT
# ==============================================================================

set -Eeuo pipefail

################################################################################
# Variables
################################################################################

readonly NETCORE_VERSION="0.1.0"

################################################################################
# Colors
################################################################################

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

################################################################################
# Logging
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[ OK ]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $*" >&2
}

################################################################################
# Header
################################################################################

print_banner() {

cat << EOF

======================================================
             NetCore Installer
                Version ${NETCORE_VERSION}
======================================================

EOF

}

################################################################################
# Root Check
################################################################################

require_root() {

    if [[ $EUID -ne 0 ]]; then
        log_error "This installer must be run as root."

        echo
        echo "Run:"
        echo "sudo ./install/install-full.sh"
        echo

        exit 1
    fi
}

################################################################################
# Ubuntu Check
################################################################################

check_os() {

    source /etc/os-release

    if [[ "${ID}" != "ubuntu" ]]; then
        log_error "Unsupported Operating System."
        exit 1
    fi

    log_success "Ubuntu detected."
}

################################################################################
# Internet Check
################################################################################

check_internet() {

    log_info "Checking Internet connectivity..."

    if ping -c 2 1.1.1.1 >/dev/null 2>&1; then
        log_success "Internet connection OK."
    else
        log_error "No Internet connection."
        exit 1
    fi
}

################################################################################
# Command Check
################################################################################

command_exists() {

    command -v "$1" >/dev/null 2>&1
}

################################################################################
# Package Installation
################################################################################

install_package() {

    local PACKAGE="$1"

    if dpkg -s "$PACKAGE" >/dev/null 2>&1; then

        log_success "$PACKAGE already installed."

    else

        log_info "Installing $PACKAGE..."

        apt-get install -y "$PACKAGE"

        log_success "$PACKAGE installed."

    fi
}

################################################################################
# Service Helpers
################################################################################

enable_service() {

    local SERVICE="$1"

    systemctl enable --now "$SERVICE"

    log_success "$SERVICE enabled."
}

restart_service() {

    local SERVICE="$1"

    systemctl restart "$SERVICE"

    log_success "$SERVICE restarted."
}

################################################################################
# Progress
################################################################################

step() {

    echo
    echo "------------------------------------------------------"
    echo "$1"
    echo "------------------------------------------------------"
}

################################################################################
# Cleanup
################################################################################

cleanup() {

    apt-get autoremove -y
    apt-get autoclean -y
}

################################################################################
# Error Handler
################################################################################

on_error() {

    local EXIT_CODE=$?

    log_error "Installer failed."

    log_error "Exit Code: ${EXIT_CODE}"

    exit "${EXIT_CODE}"
}

trap on_error ERR
