#!/usr/bin/env bash
# Shared functions for no-nonsense-orchestration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="${NO_NONSENSE_TASKS_DB:-$HOME/.no-nonsense/tasks.db}"

check_db_exists() {
	if [ ! -f "$DB_PATH" ]; then
		echo "Error: Database not initialized. Run init_db.sh first." >&2
		exit 1
	fi
}

sql_escape() {
	local input="$1"
	echo "${input//\'/\'\'}"
}

validate_task_id() {
	local task_id="$1"
	if ! [[ "$task_id" =~ ^[0-9]+$ ]]; then
		echo "Error: Task ID must be a number" >&2
		exit 1
	fi
}

validate_status() {
	local status="$1"
	case "$status" in
	backlog|todo|in-progress|done|blocked) return 0 ;;
	*)
		echo "Error: Invalid status '$status'. Must be: backlog, todo, in-progress, done, blocked" >&2
		exit 1
		;;
	esac
}

validate_role() {
	local role="$1"
	case "$role" in
	planner|breaker|implementer|tester|reviewer|"") return 0 ;;
	*)
		echo "Error: Invalid role '$role'. Must be: planner, breaker, implementer, tester, reviewer" >&2
		exit 1
		;;
	esac
}

# shellcheck disable=SC2034
STATUS_ORDER_CASE="
    CASE status
        WHEN 'in-progress' THEN 1
        WHEN 'todo' THEN 2
        WHEN 'blocked' THEN 3
        WHEN 'backlog' THEN 4
        WHEN 'done' THEN 5
    END
"
