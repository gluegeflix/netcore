#!/usr/bin/env bash
#
# ==============================================================================
# NetCore Commands Library
# ==============================================================================
# Shared command detection, execution, and retry helpers.
#
# Loaded by:
#   install/libraries/load.sh
#
# ==============================================================================

set -Eeuo pipefail


################################################################################
# Duplicate Load Protection
################################################################################

if [[ "${NETCORE_COMMANDS_LIBRARY_LOADED:-false}" == true ]]; then
    return 0
fi

NETCORE_COMMANDS_LIBRARY_LOADED=true
export NETCORE_COMMANDS_LIBRARY_LOADED


################################################################################
# Command Detection
################################################################################

command_exists() {

    local COMMAND="${1:-}"

    if [[ -z "$COMMAND" ]]; then
        log_error "command_exists requires a command name."
        return 1
    fi

    command -v "$COMMAND" >/dev/null 2>&1

}


################################################################################
# Required Command
################################################################################

require_command() {

    local COMMAND="${1:-}"
    local PACKAGE="${2:-}"

    if [[ -z "$COMMAND" ]]; then
        log_error "require_command requires a command name."
        return 1
    fi

    if command_exists "$COMMAND"; then
        return 0
    fi

    if [[ -n "$PACKAGE" ]]; then
        log_error "Required command not found: ${COMMAND}"
        log_info "Install the package: ${PACKAGE}"
    else
        log_error "Required command not found: ${COMMAND}"
    fi

    return 1

}


################################################################################
# Command Execution
################################################################################

run_command() {

    local DESCRIPTION="${1:-}"

    if [[ -z "$DESCRIPTION" ]]; then
        log_error "run_command requires a description."
        return 1
    fi

    shift

    if [[ $# -eq 0 ]]; then
        log_error "run_command requires a command."
        return 1
    fi

    log_info "$DESCRIPTION"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_warn "[DRY RUN] $*"
        return 0
    fi

    local RESULT

    if [[ "${VERBOSE:-false}" == true ]]; then

        if [[ -n "${LOG_FILE:-}" ]]; then
            set +e
            "$@" 2>&1 | tee -a "$LOG_FILE"
            RESULT=${PIPESTATUS[0]}
            set -e
        else
            set +e
            "$@"
            RESULT=$?
            set -e
        fi

    else

        if [[ -n "${LOG_FILE:-}" ]]; then
            set +e
            "$@" >>"$LOG_FILE" 2>&1
            RESULT=$?
            set -e
        else
            set +e
            "$@"
            RESULT=$?
            set -e
        fi

    fi

    if [[ $RESULT -ne 0 ]]; then
        log_error "Command failed with code ${RESULT}: $*"
        return "$RESULT"
    fi

    log_success "$DESCRIPTION"
    return 0

}


################################################################################
# Retry Command
################################################################################

retry_command() {

    local DESCRIPTION="${1:-}"
    local MAX_ATTEMPTS="${2:-3}"
    local RETRY_DELAY="${3:-5}"

    if [[ -z "$DESCRIPTION" ]]; then
        log_error "retry_command requires a description."
        return 1
    fi

    shift 3

    if [[ $# -eq 0 ]]; then
        log_error "retry_command requires a command."
        return 1
    fi

    if ! [[ "$MAX_ATTEMPTS" =~ ^[1-9][0-9]*$ ]]; then
        log_error "Invalid retry count: ${MAX_ATTEMPTS}"
        return 1
    fi

    if ! [[ "$RETRY_DELAY" =~ ^[0-9]+$ ]]; then
        log_error "Invalid retry delay: ${RETRY_DELAY}"
        return 1
    fi

    local ATTEMPT=1
    local RESULT=0

    while (( ATTEMPT <= MAX_ATTEMPTS )); do

        log_info "${DESCRIPTION} — attempt ${ATTEMPT} of ${MAX_ATTEMPTS}"

        if run_command "$DESCRIPTION" "$@"; then
            return 0
        else
            RESULT=$?
        fi

        if (( ATTEMPT < MAX_ATTEMPTS )); then
            log_warn "Retrying in ${RETRY_DELAY} seconds..."
            sleep "$RETRY_DELAY"
        fi

        ATTEMPT=$((ATTEMPT + 1))

    done

    log_error "${DESCRIPTION} failed after ${MAX_ATTEMPTS} attempts."
    return "$RESULT"

}
