#!/usr/bin/env bash
# Move a task to a different status
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
check_db_exists

TASK_ID="" NEW_STATUS=""

while [[ $# -gt 0 ]]; do
	case $1 in
	-s|--status) NEW_STATUS="$2"; shift 2;;
	-h|--help)
		echo "Usage: task_move.sh <id> --status <status>"; exit 0;;
	-*) echo "Unknown option: $1" >&2; exit 1;;
	*)  [ -z "$TASK_ID" ] && TASK_ID="$1" || { [ -z "$NEW_STATUS" ] && NEW_STATUS="$1"; }; shift;;
	esac
done

[ -z "$TASK_ID" ] || [ -z "$NEW_STATUS" ] && { echo "Usage: task_move.sh <id> --status <status>" >&2; exit 1; }
validate_task_id "$TASK_ID"
validate_status "$NEW_STATUS"

RESULT=$(sqlite3 "$DB_PATH" "UPDATE tasks SET status = '$NEW_STATUS' WHERE id = $TASK_ID; SELECT changes();")
[ "$RESULT" -eq 0 ] && { echo "Task #$TASK_ID not found" >&2; exit 1; }
echo "Task #$TASK_ID -> $NEW_STATUS"
