#!/usr/bin/env bash
#
# ==============================================================================
# NetCore Services Library
# ==============================================================================
# Shared systemd service-management helpers.
#
# Loaded by:
#   install/libraries/load.sh
#
# ==============================================================================

set -Eeuo pipefail


################################################################################
# Duplicate Load Protection
################################################################################

if [[ "${NETCORE_SERVICES_LIBRARY_LOADED:-false}" == true ]]; then
    return 0
fi

NETCORE_SERVICES_LIBRARY_LOADED=true
export NETCORE_SERVICES_LIBRARY_LOADED


################################################################################
# Service Detection
################################################################################

service_exists() {

    local SERVICE="${1:-}"

    if [[ -z "$SERVICE" ]]; then
        log_error "service_exists requires a service name."
        return 1
    fi

    if systemctl list-unit-files \
        --type=service \
        --type=socket \
        --no-legend \
        2>/dev/null \
        | awk '{print $1}' \
        | grep -Fxq "$SERVICE"; then

        return 0
    fi

    if systemctl list-unit-files \
        --type=service \
        --type=socket \
        --no-legend \
        2>/dev/null \
        | awk '{print $1}' \
        | grep -Fxq "${SERVICE}.service"; then

        return 0
    fi

    systemctl status "$SERVICE" >/dev/null 2>&1

}


################################################################################
# Active-State Check
################################################################################

is_service_active() {

    local SERVICE="${1:-}"

    if [[ -z "$SERVICE" ]]; then
        log_error "is_service_active requires a service name."
        return 1
    fi

    systemctl is-active --quiet "$SERVICE"

}


################################################################################
# Enabled-State Check
################################################################################

is_service_enabled() {

    local SERVICE="${1:-}"

    if [[ -z "$SERVICE" ]]; then
        log_error "is_service_enabled requires a service name."
        return 1
    fi

    systemctl is-enabled --quiet "$SERVICE"

}


################################################################################
# Enable Service
################################################################################

enable_service() {

    local SERVICE="${1:-}"

    if [[ -z "$SERVICE" ]]; then
        log_error "enable_service requires a service name."
        return 1
    fi

    if ! service_exists "$SERVICE"; then
        log_error "Service not found: ${SERVICE}"
        return 1
    fi

    if is_service_active "$SERVICE" && is_service_enabled "$SERVICE"; then
        log_success "${SERVICE} already enabled and running."
        return 0
    fi

    run_command \
        "Enable ${SERVICE}" \
        systemctl enable --now "$SERVICE"

}


################################################################################
# Start Service
################################################################################

start_service() {

    local SERVICE="${1:-}"

    if [[ -z "$SERVICE" ]]; then
        log_error "start_service requires a service name."
        return 1
    fi

    if ! service_exists "$SERVICE"; then
        log_error "Service not found: ${SERVICE}"
        return 1
    fi

    if is_service_active "$SERVICE"; then
        log_success "${SERVICE} already running."
        return 0
    fi

    run_command \
        "Start ${SERVICE}" \
        systemctl start "$SERVICE"

}


################################################################################
# Stop Service
################################################################################

stop_service() {

    local SERVICE="${1:-}"

    if [[ -z "$SERVICE" ]]; then
        log_error "stop_service requires a service name."
        return 1
    fi

    if ! service_exists "$SERVICE"; then
        log_error "Service not found: ${SERVICE}"
        return 1
    fi

    if ! is_service_active "$SERVICE"; then
        log_success "${SERVICE} already stopped."
        return 0
    fi

    run_command \
        "Stop ${SERVICE}" \
        systemctl stop "$SERVICE"

}


################################################################################
# Restart Service
################################################################################

restart_service() {

    local SERVICE="${1:-}"

    if [[ -z "$SERVICE" ]]; then
        log_error "restart_service requires a service name."
        return 1
    fi

    if ! service_exists "$SERVICE"; then
        log_error "Service not found: ${SERVICE}"
        return 1
    fi

    run_command \
        "Restart ${SERVICE}" \
        systemctl restart "$SERVICE"

}


################################################################################
# Reload Service
################################################################################

reload_service() {

    local SERVICE="${1:-}"

    if [[ -z "$SERVICE" ]]; then
        log_error "reload_service requires a service name."
        return 1
    fi

    if ! service_exists "$SERVICE"; then
        log_error "Service not found: ${SERVICE}"
        return 1
    fi

    if systemctl can-reload "$SERVICE" >/dev/null 2>&1; then
        run_command \
            "Reload ${SERVICE}" \
            systemctl reload "$SERVICE"
    else
        log_warn "${SERVICE} does not support reload; restarting instead."
        restart_service "$SERVICE"
    fi

}


################################################################################
# Disable Service
################################################################################

disable_service() {

    local SERVICE="${1:-}"

    if [[ -z "$SERVICE" ]]; then
        log_error "disable_service requires a service name."
        return 1
    fi

    if ! service_exists "$SERVICE"; then
        log_warn "Service not found, skipping disable: ${SERVICE}"
        return 0
    fi

    run_command \
        "Disable ${SERVICE}" \
        systemctl disable --now "$SERVICE"

}


################################################################################
# Require Service
################################################################################

require_service() {

    local SERVICE="${1:-}"
    local AUTO_START="${2:-true}"

    if [[ -z "$SERVICE" ]]; then
        log_error "require_service requires a service name."
        return 1
    fi

    case "$AUTO_START" in
        true|false)
            ;;
        *)
            log_error "require_service auto-start must be true or false."
            return 1
            ;;
    esac

    if ! service_exists "$SERVICE"; then
        log_error "Required service not found: ${SERVICE}"
        return 1
    fi

    if is_service_active "$SERVICE"; then
        return 0
    fi

    if [[ "$AUTO_START" == false ]]; then
        log_error "Required service is not running: ${SERVICE}"
        return 1
    fi

    log_info "Required service is not running: ${SERVICE}"
    start_service "$SERVICE"

}
