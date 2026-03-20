#!/usr/bin/env bash
# Delete a task by ID
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
check_db_exists

TASK_ID="${1:-}"
[ -z "$TASK_ID" ] && { echo "Usage: task_delete.sh <id>" >&2; exit 1; }
validate_task_id "$TASK_ID"

TITLE=$(sqlite3 "$DB_PATH" "SELECT title FROM tasks WHERE id = $TASK_ID;")
[ -z "$TITLE" ] && { echo "Task #$TASK_ID not found" >&2; exit 1; }
sqlite3 "$DB_PATH" "DELETE FROM tasks WHERE id = $TASK_ID;"
echo "Deleted #$TASK_ID: $TITLE"
