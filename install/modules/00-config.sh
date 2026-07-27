#!/usr/bin/env bash
#
# ==============================================================================
# NetCore Configuration Loader
# ==============================================================================

set -Eeuo pipefail


################################################################################
# Configuration Paths
################################################################################

CONFIG_DIR="${NETCORE_ROOT}/config"

USER_CONFIG="${CONFIG_DIR}/netcore.yml"

DEFAULT_CONFIG="${CONFIG_DIR}/defaults.yml"


################################################################################
# Load Configuration
################################################################################

load_config() {

    if [[ ! -f "$DEFAULT_CONFIG" ]]; then

        log_error "Missing default configuration."

        exit 1

    fi


    if [[ ! -f "$USER_CONFIG" ]]; then

        log_warn "User configuration missing."

        log_info "Using defaults."

        USER_CONFIG="$DEFAULT_CONFIG"

    fi


    log_success "Loaded configuration:"
    log_info "$USER_CONFIG"

}


################################################################################
# Get Configuration Value
################################################################################

config_get() {

    local KEY="$1"

    if [[ -z "$KEY" ]]; then

        log_error "config_get requires a key."

        return 1

    fi


    yq ".$KEY" "$USER_CONFIG" 2>/dev/null | tr -d '"'

}


################################################################################
# Show Configuration
################################################################################

show_config() {

    echo

    echo "NetCore Configuration"

    echo "---------------------"


    echo "Hostname:"
    config_get hostname


    echo

    echo "Timezone:"
    config_get timezone


    echo

    echo "Network:"

    echo "IP:"
    config_get network.ip


    echo "Gateway:"
    config_get network.gateway

}
