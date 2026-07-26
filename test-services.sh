#!/usr/bin/env bash

set -Eeuo pipefail

export NETCORE_ROOT="$(pwd)"

source install/modules/00-common.sh
source install/modules/00-config.sh
source install/modules/04-services.sh

parse_args "$@"

init_logging

print_banner

install_services
