CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    tags TEXT DEFAULT '',
    status TEXT DEFAULT 'backlog' CHECK(status IN ('backlog', 'todo', 'in-progress', 'done', 'blocked')),
    role TEXT DEFAULT '' CHECK(role IN ('', 'planner', 'breaker', 'implementer', 'tester', 'reviewer')),
    assignee TEXT DEFAULT '',
    context TEXT DEFAULT '',
    parent_id INTEGER DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES tasks(id)
);

CREATE INDEX IF NOT EXISTS idx_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_role ON tasks(role);
CREATE INDEX IF NOT EXISTS idx_parent ON tasks(parent_id);
CREATE INDEX IF NOT EXISTS idx_created_at ON tasks(created_at);

CREATE TRIGGER IF NOT EXISTS update_timestamp
AFTER UPDATE ON tasks
BEGIN
    UPDATE tasks SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;
