#!/usr/bin/env bash
# Filter tasks by tag (exact match within comma-separated list)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
check_db_exists

TAG="${1:-}"
[ -z "$TAG" ] && { echo "Usage: task_filter.sh <tag>" >&2; exit 1; }
TAG_ESC=$(sql_escape "$TAG")

RESULT=$(sqlite3 -header -column "$DB_PATH" <<EOF
SELECT id as ID, status as Status, role as Role, title as Title, tags as Tags
FROM tasks
WHERE tags = '$TAG_ESC'
   OR tags LIKE '$TAG_ESC,%'
   OR tags LIKE '%,$TAG_ESC'
   OR tags LIKE '%,$TAG_ESC,%'
ORDER BY $STATUS_ORDER_CASE, created_at DESC;
EOF
)

[ -z "$RESULT" ] && { echo "No tasks with tag: $TAG"; exit 0; }
echo "$RESULT"
