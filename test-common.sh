#!/usr/bin/env bash

source install/modules/00-common.sh

print_banner

log_info "Testing info"
log_success "Testing success"
log_warn "Testing warning"
log_error "Testing error"

check_os
check_internet
