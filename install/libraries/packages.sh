#!/usr/bin/env bash
#
# ==============================================================================
# NetCore Packages Library
# ==============================================================================
# Shared Ubuntu package-management helpers.
#
# Loaded by:
#   install/libraries/load.sh
#
# ==============================================================================

set -Eeuo pipefail


################################################################################
# Duplicate Load Protection
################################################################################

if [[ "${NETCORE_PACKAGES_LIBRARY_LOADED:-false}" == true ]]; then
    return 0
fi

NETCORE_PACKAGES_LIBRARY_LOADED=true
export NETCORE_PACKAGES_LIBRARY_LOADED


################################################################################
# Package Detection
################################################################################

package_is_installed() {

    local PACKAGE="${1:-}"

    if [[ -z "$PACKAGE" ]]; then
        log_error "package_is_installed requires a package name."
        return 1
    fi

    dpkg-query \
        --show \
        --showformat='${db:Status-Status}' \
        "$PACKAGE" \
        2>/dev/null \
        | grep -qx "installed"

}


################################################################################
# Install Package
################################################################################

install_package() {

    local PACKAGE="${1:-}"

    if [[ -z "$PACKAGE" ]]; then
        log_error "install_package requires a package name."
        return 1
    fi

    if package_is_installed "$PACKAGE"; then
        log_success "${PACKAGE} already installed."
        return 0
    fi

    retry_command \
        "Installing ${PACKAGE}" \
        3 \
        5 \
        env DEBIAN_FRONTEND=noninteractive \
        apt-get install -y "$PACKAGE"

}


################################################################################
# Require Package
################################################################################

require_package() {

    local PACKAGE="${1:-}"
    local AUTO_INSTALL="${2:-true}"

    if [[ -z "$PACKAGE" ]]; then
        log_error "require_package requires a package name."
        return 1
    fi

    case "$AUTO_INSTALL" in
        true|false)
            ;;
        *)
            log_error "require_package auto-install must be true or false."
            return 1
            ;;
    esac

    if package_is_installed "$PACKAGE"; then
        return 0
    fi

    if [[ "$AUTO_INSTALL" == false ]]; then
        log_error "Required package is not installed: ${PACKAGE}"
        return 1
    fi

    log_info "Required package missing: ${PACKAGE}"
    install_package "$PACKAGE"

}
