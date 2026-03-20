#!/usr/bin/env bash
# Show details of a single task
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
check_db_exists

TASK_ID="$1"
[ -z "${TASK_ID:-}" ] && { echo "Usage: task_show.sh <id>" >&2; exit 1; }
validate_task_id "$TASK_ID"

RESULT=$(sqlite3 "$DB_PATH" <<EOF
.mode line
SELECT id as 'ID', title as 'Title', description as 'Description',
       tags as 'Tags', status as 'Status', role as 'Role',
       assignee as 'Assignee', context as 'Context',
       parent_id as 'Parent', created_at as 'Created', updated_at as 'Updated'
FROM tasks WHERE id = $TASK_ID;
EOF
)

[ -z "$RESULT" ] && { echo "Task #$TASK_ID not found" >&2; exit 1; }
echo "$RESULT"
