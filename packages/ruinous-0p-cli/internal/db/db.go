package db

import (
	"context"
	"database/sql"
	"embed"
	"fmt"
	"time"

	_ "modernc.org/sqlite"
)

//go:embed schema.sql
var schemaFS embed.FS

// DB wraps a sql.DB with migration capabilities
type DB struct {
	sqlDB *sql.DB
}

// New opens a database connection and runs migrations
func New(dataDir string) (*DB, error) {
	dsn := fmt.Sprintf("file:%s/ops.db?_fk=1", dataDir)
	sqlDB, err := sql.Open("sqlite", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	if err := sqlDB.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	db := &DB{sqlDB: sqlDB}
	if err := db.migrate(); err != nil {
		return nil, fmt.Errorf("failed to migrate database: %w", err)
	}

	return db, nil
}

// Close closes the database connection
func (db *DB) Close() error {
	return db.sqlDB.Close()
}

// migrate runs the schema migration
func (db *DB) migrate() error {
	schema, err := schemaFS.ReadFile("schema.sql")
	if err != nil {
		return fmt.Errorf("failed to read schema: %w", err)
	}

	if _, err := db.sqlDB.Exec(string(schema)); err != nil {
		return fmt.Errorf("failed to execute schema: %w", err)
	}

	return nil
}

// Op represents an operation
type Op struct {
	ID        string
	State     string
	Mode      string
	CreatedAt time.Time
	UpdatedAt time.Time
}

// OpRepo represents a repository associated with an op
type OpRepo struct {
	OpID         string
	RepoName     string
	Branch       string
	WorktreePath string
}

// OpDeck represents a deck associated with an op
type OpDeck struct {
	OpID      string
	DeckName  string
	IsPrimary bool
}

// CreateOp creates a new op with its repos and decks
func (db *DB) CreateOp(ctx context.Context, op *Op, repos []OpRepo, decks []OpDeck) error {
	tx, err := db.sqlDB.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Insert op
	_, err = tx.ExecContext(ctx,
		"INSERT INTO ops (id, state, mode, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
		op.ID, op.State, op.Mode, op.CreatedAt.Format(time.RFC3339), op.UpdatedAt.Format(time.RFC3339))
	if err != nil {
		return fmt.Errorf("failed to insert op: %w", err)
	}

	// Insert repos
	for _, repo := range repos {
		_, err = tx.ExecContext(ctx,
			"INSERT INTO op_repos (op_id, repo_name, branch, worktree_path) VALUES (?, ?, ?, ?)",
			repo.OpID, repo.RepoName, repo.Branch, repo.WorktreePath)
		if err != nil {
			return fmt.Errorf("failed to insert repo: %w", err)
		}
	}

	// Insert decks
	for _, deck := range decks {
		isPrimary := 0
		if deck.IsPrimary {
			isPrimary = 1
		}
		_, err = tx.ExecContext(ctx,
			"INSERT INTO op_decks (op_id, deck_name, is_primary) VALUES (?, ?, ?)",
			deck.OpID, deck.DeckName, isPrimary)
		if err != nil {
			return fmt.Errorf("failed to insert deck: %w", err)
		}
	}

	return tx.Commit()
}

// GetOp retrieves an op by ID with its repos and decks
func (db *DB) GetOp(ctx context.Context, id string) (*Op, []OpRepo, []OpDeck, error) {
	// Get op
	row := db.sqlDB.QueryRowContext(ctx,
		"SELECT id, state, mode, created_at, updated_at FROM ops WHERE id = ?", id)

	var op Op
	var createdAtStr, updatedAtStr string
	err := row.Scan(&op.ID, &op.State, &op.Mode, &createdAtStr, &updatedAtStr)
	if err == sql.ErrNoRows {
		return nil, nil, nil, fmt.Errorf("op not found: %s", id)
	}
	if err != nil {
		return nil, nil, nil, fmt.Errorf("failed to scan op: %w", err)
	}

	op.CreatedAt, _ = time.Parse(time.RFC3339, createdAtStr)
	op.UpdatedAt, _ = time.Parse(time.RFC3339, updatedAtStr)

	// Get repos
	rows, err := db.sqlDB.QueryContext(ctx,
		"SELECT op_id, repo_name, branch, worktree_path FROM op_repos WHERE op_id = ?", id)
	if err != nil {
		return nil, nil, nil, fmt.Errorf("failed to query repos: %w", err)
	}
	defer rows.Close()

	var repos []OpRepo
	for rows.Next() {
		var repo OpRepo
		if err := rows.Scan(&repo.OpID, &repo.RepoName, &repo.Branch, &repo.WorktreePath); err != nil {
			return nil, nil, nil, fmt.Errorf("failed to scan repo: %w", err)
		}
		repos = append(repos, repo)
	}

	// Get decks
	rows2, err := db.sqlDB.QueryContext(ctx,
		"SELECT op_id, deck_name, is_primary FROM op_decks WHERE op_id = ?", id)
	if err != nil {
		return nil, nil, nil, fmt.Errorf("failed to query decks: %w", err)
	}
	defer rows2.Close()

	var decks []OpDeck
	for rows2.Next() {
		var deck OpDeck
		var isPrimary int
		if err := rows2.Scan(&deck.OpID, &deck.DeckName, &isPrimary); err != nil {
			return nil, nil, nil, fmt.Errorf("failed to scan deck: %w", err)
		}
		deck.IsPrimary = isPrimary == 1
		decks = append(decks, deck)
	}

	return &op, repos, decks, nil
}

// UpdateOp updates an op's state and mode
func (db *DB) UpdateOp(ctx context.Context, op *Op) error {
	result, err := db.sqlDB.ExecContext(ctx,
		"UPDATE ops SET state = ?, mode = ?, updated_at = ? WHERE id = ?",
		op.State, op.Mode, time.Now().Format(time.RFC3339), op.ID)
	if err != nil {
		return fmt.Errorf("failed to update op: %w", err)
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}
	if rows == 0 {
		return fmt.Errorf("op not found: %s", op.ID)
	}

	return nil
}

// DeleteOp deletes an op and its associated repos and decks
func (db *DB) DeleteOp(ctx context.Context, id string) error {
	result, err := db.sqlDB.ExecContext(ctx, "DELETE FROM ops WHERE id = ?", id)
	if err != nil {
		return fmt.Errorf("failed to delete op: %w", err)
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}
	if rows == 0 {
		return fmt.Errorf("op not found: %s", id)
	}

	return nil
}

// ListOps retrieves all ops
func (db *DB) ListOps(ctx context.Context) ([]Op, error) {
	rows, err := db.sqlDB.QueryContext(ctx,
		"SELECT id, state, mode, created_at, updated_at FROM ops ORDER BY created_at DESC")
	if err != nil {
		return nil, fmt.Errorf("failed to query ops: %w", err)
	}
	defer rows.Close()

	var ops []Op
	for rows.Next() {
		var op Op
		var createdAtStr, updatedAtStr string
		if err := rows.Scan(&op.ID, &op.State, &op.Mode, &createdAtStr, &updatedAtStr); err != nil {
			return nil, fmt.Errorf("failed to scan op: %w", err)
		}
		op.CreatedAt, _ = time.Parse(time.RFC3339, createdAtStr)
		op.UpdatedAt, _ = time.Parse(time.RFC3339, updatedAtStr)
		ops = append(ops, op)
	}

	return ops, nil
}

// GetOpRepo retrieves the primary repo for an op
func (db *DB) GetOpRepo(ctx context.Context, opID string) (*OpRepo, error) {
	row := db.sqlDB.QueryRowContext(ctx,
		"SELECT op_id, repo_name, branch, worktree_path FROM op_repos WHERE op_id = ? LIMIT 1", opID)

	var repo OpRepo
	err := row.Scan(&repo.OpID, &repo.RepoName, &repo.Branch, &repo.WorktreePath)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("no repo found for op: %s", opID)
	}
	if err != nil {
		return nil, fmt.Errorf("failed to scan repo: %w", err)
	}

	return &repo, nil
}

// GetOpDeck retrieves the primary deck for an op
func (db *DB) GetOpDeck(ctx context.Context, opID string) (*OpDeck, error) {
	row := db.sqlDB.QueryRowContext(ctx,
		"SELECT op_id, deck_name, is_primary FROM op_decks WHERE op_id = ? AND is_primary = 1 LIMIT 1", opID)

	var deck OpDeck
	var isPrimary int
	err := row.Scan(&deck.OpID, &deck.DeckName, &isPrimary)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("no deck found for op: %s", opID)
	}
	if err != nil {
		return nil, fmt.Errorf("failed to scan deck: %w", err)
	}

	deck.IsPrimary = isPrimary == 1
	return &deck, nil
}
