CREATE TABLE IF NOT EXISTS ops (
    id TEXT PRIMARY KEY,
    state TEXT NOT NULL,
    mode TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS op_repos (
    op_id TEXT NOT NULL REFERENCES ops(id) ON DELETE CASCADE,
    repo_name TEXT NOT NULL,
    branch TEXT NOT NULL,
    worktree_path TEXT NOT NULL,
    PRIMARY KEY (op_id, repo_name)
);

CREATE TABLE IF NOT EXISTS op_decks (
    op_id TEXT NOT NULL REFERENCES ops(id) ON DELETE CASCADE,
    deck_name TEXT NOT NULL,
    is_primary INTEGER DEFAULT 1,
    PRIMARY KEY (op_id, deck_name)
);
