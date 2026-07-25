#!/usr/bin/env bash

source install/modules/00-common.sh

parse_args "$@"

init_logging

print_banner

echo "NetCore Root: $NETCORE_ROOT"

log_info "Testing information log"
log_success "Testing success log"
log_warn "Testing warning log"

check_os
check_internet

run_command "Testing command wrapper" sleep 3

echo
echo "Test complete"
