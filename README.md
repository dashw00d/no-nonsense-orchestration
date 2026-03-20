# no-nonsense-orchestration

Autonomous AI agent orchestration with a single cron job and a SQLite task board.

One cron fires. It reads the board, assigns tasks to role-based agents, and they create follow-up tasks for each other. The cycle repeats until the board is clear.

## How it works

```
                    ┌─────────────┐
                    │  Cron fires  │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │ Orchestrator │  reads orchestrator.md
                    │  reads board │  spawns agents by role
                    └──────┬──────┘
                           │
          ┌────────┬───────┼───────┬─────────┐
          ▼        ▼       ▼       ▼         ▼
      Planner  Breaker  Implmtr  Tester  Reviewer
          │        │       │       │         │
          │    creates   does    tests    reviews
          │    subtasks  work    work      work
          │        │       │       │         │
          └────────┴───────┴───────┴─────────┘
                           │
                    tasks flow back to board
                    next cron cycle picks them up
```

## Pipeline

Tasks flow through roles:

| Role | Job | Creates |
|------|-----|---------|
| **planner** | Analyzes goal, writes a plan | `breaker` task |
| **breaker** | Takes plan, creates subtasks | `implementer` / `tester` / `reviewer` tasks |
| **implementer** | Does the work | `tester` task (optional) |
| **tester** | Validates the work | `implementer` task on failure |
| **reviewer** | Checks quality | `implementer` task on issues |

Not every task needs all roles. Simple tasks can start at any role.

## Requirements

- `bash`
- `sqlite3`
- An AI agent runtime that can spawn sub-agents (Claude Code, OpenClaw, etc.)

## Setup

```bash
git clone https://github.com/openclaw/no-nonsense-orchestration.git
cd no-nonsense-orchestration

# Initialize the database
bash scripts/init_db.sh

# Default DB location: ~/.no-nonsense/tasks.db
# Override: export NO_NONSENSE_TASKS_DB=/path/to/tasks.db
```

## Usage

### Add tasks

```bash
T=scripts

# High-level goal — starts with planning
$T/task_add.sh "Add user authentication" --role planner --status todo \
  --context "Need JWT auth on all /api routes. Exclude /health and /login."

# Simple task — goes straight to implementation
$T/task_add.sh "Fix null pointer in user lookup" --role implementer --status todo \
  --context "user_search() crashes when email is None. Add null check."

# Check the board
$T/task_list.sh
$T/task_stats.sh
```

### Run the orchestrator

Point your agent's cron/scheduler at `orchestrator.md`:

```
Read and follow orchestrator.md.
Task scripts are at: /path/to/no-nonsense-orchestration/scripts/
Role docs are at: /path/to/no-nonsense-orchestration/roles/
```

The orchestrator will:
1. Read the task board
2. Assign `todo` tasks to agents by role
3. Unblock stuck tasks
4. Promote backlog items when the pipeline is empty

### Manual task management

```bash
$T/task_list.sh                        # all tasks
$T/task_list.sh --status todo          # just todo
$T/task_list.sh --role implementer     # by role
$T/task_list.sh --unassigned           # unassigned only

$T/task_show.sh 3                      # task details
$T/task_move.sh 3 --status in-progress # change status
$T/task_update.sh 3 --context "new info" --assignee "me"
$T/task_filter.sh urgent               # filter by tag
$T/task_stats.sh                       # summary
$T/task_delete.sh 3                    # delete
```

## Task fields

| Field | Description |
|-------|-------------|
| `id` | Auto-increment integer |
| `title` | Short task title |
| `description` | Longer description |
| `tags` | Comma-separated tags (e.g. `urgent,seq:1`) |
| `status` | `backlog`, `todo`, `in-progress`, `done`, `blocked` |
| `role` | `planner`, `breaker`, `implementer`, `tester`, `reviewer` |
| `assignee` | Who/what is working on it |
| `context` | Execution context — plans, instructions, results |
| `parent_id` | Parent task ID for subtask trees |

## Customization

### Add your own roles

Create a new markdown file in `roles/` and add the role name to the `CHECK` constraint in `migrations/001_initial_schema.sql` and `validate_role()` in `scripts/lib.sh`.

### Change the schedule

The orchestrator is just a markdown doc. Point any scheduler at it — cron, heartbeat, manual trigger, whatever.

### Tune concurrency

Edit `orchestrator.md` — the default max is 3 concurrent agents.

## Database

SQLite at `~/.no-nonsense/tasks.db`. Override with `NO_NONSENSE_TASKS_DB` env var.

Schema is managed by migrations in `migrations/`. Run `scripts/init_db.sh` to apply new migrations — it's idempotent.

## Credits

Task manager based on [no-nonsense-tasks](https://github.com/openclaw/skills/tree/main/skills/dvjn/no-nonsense-tasks) by dvjn.

## License

MIT
