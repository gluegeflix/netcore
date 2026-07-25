#!/usr/bin/env bash

set -Eeuo pipefail

export NETCORE_ROOT="$(pwd)"

source install/modules/00-common.sh

init_logging


TEST_FILE="/tmp/netcore-test.conf"


echo "original configuration" > "$TEST_FILE"


backup_file "$TEST_FILE"


BACKUP=$(ls -t ${TEST_FILE}.netcore-backup-* | head -1)


echo "modified configuration" > "$TEST_FILE"


log_info "Current file:"
cat "$TEST_FILE"


restore_backup "$BACKUP" "$TEST_FILE"


log_info "Restored file:"
cat "$TEST_FILE"
