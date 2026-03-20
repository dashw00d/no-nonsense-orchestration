#!/usr/bin/env bash
# List tasks with optional filters
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
check_db_exists

STATUS_FILTER="" ROLE_FILTER="" UNASSIGNED=false

while [[ $# -gt 0 ]]; do
	case $1 in
	-s|--status)    STATUS_FILTER="$2"; shift 2;;
	-r|--role)      ROLE_FILTER="$2"; shift 2;;
	--unassigned)   UNASSIGNED=true; shift;;
	-h|--help)
		cat <<'USAGE'
Usage: task_list.sh [options]

Options:
  -s, --status STATUS   Filter by status
  -r, --role ROLE       Filter by role
  --unassigned          Show only unassigned tasks
USAGE
		exit 0;;
	-*) echo "Unknown option: $1" >&2; exit 1;;
	*)  [ -z "$STATUS_FILTER" ] && STATUS_FILTER="$1"; shift;;
	esac
done

WHERE_CLAUSES=()
[ -n "$STATUS_FILTER" ] && WHERE_CLAUSES+=("status = '$(sql_escape "$STATUS_FILTER")'")
[ -n "$ROLE_FILTER" ]   && WHERE_CLAUSES+=("role = '$(sql_escape "$ROLE_FILTER")'")
[ "$UNASSIGNED" = true ] && WHERE_CLAUSES+=("(assignee = '' OR assignee IS NULL)")

WHERE=""
if [ ${#WHERE_CLAUSES[@]} -gt 0 ]; then
	WHERE="WHERE $(IFS=' AND '; echo "${WHERE_CLAUSES[*]}")"
fi

RESULT=$(sqlite3 -header -column "$DB_PATH" <<EOF
SELECT id as ID, status as Status, role as Role, assignee as Assignee,
       title as Title, tags as Tags, substr(created_at,1,16) as Created
FROM tasks $WHERE
ORDER BY $STATUS_ORDER_CASE, created_at DESC;
EOF
)

[ -z "$RESULT" ] && { echo "No tasks found."; exit 0; }
echo "$RESULT"
