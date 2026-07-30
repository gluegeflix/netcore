#!/usr/bin/env bash
#
# ==============================================================================
# NetCore Installer
# ==============================================================================
# Main installation launcher
#
# ==============================================================================

set -Eeuo pipefail

################################################################################
# Determine NetCore Root
################################################################################

NETCORE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export NETCORE_ROOT

################################################################################
# Load Core Framework
################################################################################

source "${NETCORE_ROOT}/install/modules/00-common.sh"
source "${NETCORE_ROOT}/install/modules/00-config.sh"

################################################################################
# Module Configuration
################################################################################

MODULES=(
    system
    network
    security
    services
)

module_file() {

    case "$1" in
        system)   echo "01-system.sh" ;;
        network)  echo "02-network.sh" ;;
        security) echo "03-security.sh" ;;
        services) echo "04-services.sh" ;;
        *)
            log_error "Unknown module: $1"
            return 1
            ;;
    esac

}

################################################################################
# Load Modules
################################################################################

for MODULE in "${MODULES[@]}"; do
    source "${NETCORE_ROOT}/install/modules/$(module_file "$MODULE")"
done

################################################################################
# Module Runner
################################################################################

run_module() {

    local MODULE="$1"
    local INSTALL_FUNCTION="install_${MODULE}"

    if ! declare -f "$INSTALL_FUNCTION" >/dev/null; then
        log_error "No installer function found: ${INSTALL_FUNCTION}"
        return 1
    fi

    "$INSTALL_FUNCTION"

}

################################################################################
# Main
################################################################################

main() {

    parse_args "$@"
    init_logging
    print_banner
    load_config

    for MODULE in "${MODULES[@]}"; do
        run_module "$MODULE"
    done

    log_success "NetCore installation completed."

}

main "$@"
