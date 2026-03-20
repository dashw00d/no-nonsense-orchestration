#!/usr/bin/env bash
# Update one or more fields on a task
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
check_db_exists

TASK_ID="" UPDATES=()

while [[ $# -gt 0 ]]; do
	case $1 in
	--title)          UPDATES+=("title = '$(sql_escape "$2")'"); shift 2;;
	-d|--description) UPDATES+=("description = '$(sql_escape "$2")'"); shift 2;;
	-t|--tags)        UPDATES+=("tags = '$(sql_escape "$2")'"); shift 2;;
	-s|--status)      validate_status "$2"; UPDATES+=("status = '$2'"); shift 2;;
	-r|--role)        validate_role "$2"; UPDATES+=("role = '$2'"); shift 2;;
	-a|--assignee)    UPDATES+=("assignee = '$(sql_escape "$2")'"); shift 2;;
	-c|--context)     UPDATES+=("context = '$(sql_escape "$2")'"); shift 2;;
	-p|--parent)      validate_task_id "$2"; UPDATES+=("parent_id = $2"); shift 2;;
	-h|--help)
		cat <<'USAGE'
Usage: task_update.sh <id> [options]

Options:
  --title TEXT             Update title
  -d, --description TEXT   Update description
  -t, --tags TAGS          Update tags
  -s, --status STATUS      Update status
  -r, --role ROLE          Update role
  -a, --assignee TEXT      Update assignee
  -c, --context TEXT       Update context
  -p, --parent ID          Update parent task ID
USAGE
		exit 0;;
	-*) echo "Unknown option: $1" >&2; exit 1;;
	*)  [ -z "$TASK_ID" ] && TASK_ID="$1"; shift;;
	esac
done

[ -z "$TASK_ID" ] || [ ${#UPDATES[@]} -eq 0 ] && { echo "Usage: task_update.sh <id> --field value ..." >&2; exit 1; }
validate_task_id "$TASK_ID"

SET_CLAUSE=$(IFS=', '; echo "${UPDATES[*]}")
RESULT=$(sqlite3 "$DB_PATH" "UPDATE tasks SET $SET_CLAUSE WHERE id = $TASK_ID; SELECT changes();")
[ "$RESULT" -eq 0 ] && { echo "Task #$TASK_ID not found" >&2; exit 1; }
echo "Task #$TASK_ID updated"
