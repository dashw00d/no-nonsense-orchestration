#!/usr/bin/env bash
# Show task statistics grouped by status and role
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
check_db_exists

TOTAL=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM tasks;")
[ "$TOTAL" -eq 0 ] && { echo "No tasks."; exit 0; }

sqlite3 -header -column "$DB_PATH" <<EOF
SELECT status as Status, role as Role, COUNT(*) as Count
FROM tasks GROUP BY status, role
ORDER BY $STATUS_ORDER_CASE;
EOF
echo "Total: $TOTAL"
