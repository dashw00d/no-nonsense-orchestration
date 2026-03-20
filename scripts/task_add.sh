#!/usr/bin/env bash
# Add a new task
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

TITLE="" DESCRIPTION="" TAGS="" STATUS="backlog" ROLE="" CONTEXT="" PARENT_ID=""

while [[ $# -gt 0 ]]; do
	case $1 in
	-d|--description) DESCRIPTION="$2"; shift 2;;
	-t|--tags)        TAGS="$2"; shift 2;;
	-s|--status)      STATUS="$2"; shift 2;;
	-r|--role)        ROLE="$2"; shift 2;;
	-c|--context)     CONTEXT="$2"; shift 2;;
	-p|--parent)      PARENT_ID="$2"; shift 2;;
	-h|--help)
		cat <<'USAGE'
Usage: task_add.sh <title> [options]

Options:
  -d, --description TEXT   Task description
  -t, --tags TAGS          Comma-separated tags
  -s, --status STATUS      backlog (default), todo, in-progress, done, blocked
  -r, --role ROLE          planner, implementer, tester, reviewer
  -c, --context TEXT       Execution context for the assigned agent
  -p, --parent ID          Parent task ID
USAGE
		exit 0;;
	-*) echo "Unknown option: $1" >&2; exit 1;;
	*)  [ -z "$TITLE" ] && TITLE="$1" || { echo "Unexpected: $1" >&2; exit 1; }; shift;;
	esac
done

[ -z "$TITLE" ] && { echo "Error: Title required" >&2; exit 1; }
check_db_exists
validate_status "$STATUS"
[ -n "$ROLE" ] && validate_role "$ROLE"
[ -n "$PARENT_ID" ] && validate_task_id "$PARENT_ID"

TITLE_ESC=$(sql_escape "$TITLE")
DESC_ESC=$(sql_escape "$DESCRIPTION")
TAGS_ESC=$(sql_escape "$TAGS")
CTX_ESC=$(sql_escape "$CONTEXT")
PARENT_SQL="${PARENT_ID:-NULL}"

sqlite3 "$DB_PATH" <<EOF
INSERT INTO tasks (title, description, tags, status, role, context, parent_id)
VALUES ('$TITLE_ESC', '$DESC_ESC', '$TAGS_ESC', '$STATUS', '$ROLE', '$CTX_ESC', $PARENT_SQL);
SELECT 'Task #' || last_insert_rowid() || ' added (' || '$STATUS' || ')';
EOF
