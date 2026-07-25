#!/usr/bin/env bash
#
# ==============================================================================
# NetCore Main Launcher
# ==============================================================================
# Central entry point for NetCore installation modules.
# ==============================================================================


set -Eeuo pipefail


################################################################################
# Determine Project Root
################################################################################

export NETCORE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


################################################################################
# Paths
################################################################################

MODULE_DIR="${NETCORE_ROOT}/install/modules"


################################################################################
# Load Core Libraries
################################################################################

source "${MODULE_DIR}/00-common.sh"
source "${MODULE_DIR}/00-config.sh"


################################################################################
# Module Runner
################################################################################

run_module() {

    local MODULE="$1"

    local MODULE_PATH="${MODULE_DIR}/${MODULE}"


    if [[ ! -f "$MODULE_PATH" ]]; then

        log_error "Module not found: ${MODULE}"

        exit 1

    fi


    log_info "Running module: ${MODULE}"


    source "$MODULE_PATH"

}


################################################################################
# Usage
################################################################################

usage() {

cat <<EOF

NetCore Installer

Usage:

./netcore.sh <module> [options]


Available modules:

01-system.sh

Options:

--verbose
--dry-run
--help


Examples:

sudo ./netcore.sh 01-system.sh

sudo ./netcore.sh 01-system.sh --dry-run

EOF

}


################################################################################
# Main
################################################################################

main() {


    if [[ $# -lt 1 ]]; then

        usage

        exit 1

    fi


    local MODULE="$1"

    shift


    init_logging


    parse_args "$@"


    print_banner


    require_root


    load_config


    run_module "$MODULE"

}


main "$@"
