#!/usr/bin/env bash

set -Eeuo pipefail

export NETCORE_ROOT="$(pwd)"

source install/modules/00-common.sh
source install/modules/00-config.sh
source install/modules/01-system.sh

init_logging

load_config

configure_hardware_monitoring
