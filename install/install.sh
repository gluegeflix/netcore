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

source "${NETCORE_ROOT}/install/modules/00-common.sh"
source "${NETCORE_ROOT}/install/modules/00-config.sh"
source "${NETCORE_ROOT}/install/modules/01-system.sh"
source "${NETCORE_ROOT}/install/modules/02-network.sh"
source "${NETCORE_ROOT}/install/modules/03-security.sh"
source "${NETCORE_ROOT}/install/modules/04-services.sh"
################################################################################
# Load Core Framework
################################################################################

source "${NETCORE_ROOT}/install/modules/00-common.sh"
source "${NETCORE_ROOT}/install/modules/00-config.sh"


################################################################################
# Load Modules
################################################################################

MODULES=(

    "01-system.sh"
    "02-network.sh"
    "03-security.sh"
    "04-services.sh"

)


for MODULE in "${MODULES[@]}"; do

    source "${NETCORE_ROOT}/install/modules/${MODULE}"

done


################################################################################
# Module Runner
################################################################################

run_module() {

    local MODULE="$1"


    step "Running ${MODULE}"


    if declare -f "install_${MODULE}" >/dev/null; then

        install_${MODULE}

        log_success "${MODULE} completed."

    else

        log_warn "No installer function found for ${MODULE}"

    fi

}
################################################################################
# Main
################################################################################

main() {

    init_logging

    load_config


    install_system


    install_network


    install_security


    install_services


    log_success "NetCore installation completed."

}


main "$@"
