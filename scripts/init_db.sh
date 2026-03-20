#!/usr/bin/env bash
# Initialize or migrate the task database
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

DB_DIR=$(dirname "$DB_PATH")
MIGRATIONS_DIR="$SCRIPT_DIR/../migrations"

mkdir -p "$DB_DIR"

sqlite3 "$DB_PATH" <<'SQL'
CREATE TABLE IF NOT EXISTS schema_migrations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    migration_name TEXT NOT NULL UNIQUE,
    applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL

echo "Database: $DB_PATH"

applied=0; skipped=0
for f in "$MIGRATIONS_DIR"/*.sql; do
	[ ! -f "$f" ] && continue
	name=$(basename "$f")
	name_esc=$(sql_escape "$name")
	already=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM schema_migrations WHERE migration_name = '$name_esc';")
	if [ "$already" -eq 1 ]; then
		echo "  skip: $name"
		skipped=$((skipped + 1))
	else
		if sqlite3 "$DB_PATH" < "$f"; then
			sqlite3 "$DB_PATH" "INSERT INTO schema_migrations (migration_name) VALUES ('$name_esc');"
			echo "  applied: $name"
			applied=$((applied + 1))
		else
			echo "  FAILED: $name" >&2; exit 1
		fi
	fi
done

echo "Applied: $applied  Skipped: $skipped  Ready."
