package db

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestCreateOp(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	ctx := context.Background()
	op := &Op{
		ID:        "test-op",
		State:     "active",
		Mode:      "interactive",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	repos := []OpRepo{
		{OpID: "test-op", RepoName: "nix-config", Branch: "op/test-op", WorktreePath: "/tmp/test"},
	}
	decks := []OpDeck{
		{OpID: "test-op", DeckName: "chassis", IsPrimary: true},
	}

	err := db.CreateOp(ctx, op, repos, decks)
	require.NoError(t, err)

	// Verify op was created
	retrievedOp, retrievedRepos, retrievedDecks, err := db.GetOp(ctx, "test-op")
	require.NoError(t, err)
	assert.Equal(t, op.ID, retrievedOp.ID)
	assert.Equal(t, op.State, retrievedOp.State)
	assert.Equal(t, op.Mode, retrievedOp.Mode)
	assert.Len(t, retrievedRepos, 1)
	assert.Equal(t, "nix-config", retrievedRepos[0].RepoName)
	assert.Len(t, retrievedDecks, 1)
	assert.Equal(t, "chassis", retrievedDecks[0].DeckName)
}

func TestGetOp_NotFound(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	ctx := context.Background()
	_, _, _, err := db.GetOp(ctx, "non-existent")
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "not found")
}

func TestUpdateOp(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	ctx := context.Background()
	op := &Op{
		ID:        "test-op",
		State:     "active",
		Mode:      "interactive",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	err := db.CreateOp(ctx, op, nil, nil)
	require.NoError(t, err)

	// Update op
	op.State = "suspended"
	op.Mode = "autonomous"
	err = db.UpdateOp(ctx, op)
	require.NoError(t, err)

	// Verify update
	retrievedOp, _, _, err := db.GetOp(ctx, "test-op")
	require.NoError(t, err)
	assert.Equal(t, "suspended", retrievedOp.State)
	assert.Equal(t, "autonomous", retrievedOp.Mode)
}

func TestDeleteOp(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	ctx := context.Background()
	op := &Op{
		ID:        "test-op",
		State:     "active",
		Mode:      "interactive",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	err := db.CreateOp(ctx, op, nil, nil)
	require.NoError(t, err)

	// Delete op
	err = db.DeleteOp(ctx, "test-op")
	require.NoError(t, err)

	// Verify deletion
	_, _, _, err = db.GetOp(ctx, "test-op")
	assert.Error(t, err)
}

func TestListOps(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	ctx := context.Background()

	// Create multiple ops
	for i := 0; i < 3; i++ {
		op := &Op{
			ID:        fmt.Sprintf("test-op-%d", i),
			State:     "active",
			Mode:      "interactive",
			CreatedAt: time.Now().Add(time.Duration(i) * time.Second),
			UpdatedAt: time.Now(),
		}
		err := db.CreateOp(ctx, op, nil, nil)
		require.NoError(t, err)
	}

	// List ops
	ops, err := db.ListOps(ctx)
	require.NoError(t, err)
	assert.Len(t, ops, 3)
}

func TestCreateOp_DuplicateID(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	ctx := context.Background()
	op := &Op{
		ID:        "test-op",
		State:     "active",
		Mode:      "interactive",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	err := db.CreateOp(ctx, op, nil, nil)
	require.NoError(t, err)

	// Try to create with same ID
	err = db.CreateOp(ctx, op, nil, nil)
	assert.Error(t, err)
}

// setupTestDB creates a temporary database for testing
func setupTestDB(t *testing.T) *DB {
	tmpDir := t.TempDir()
	db, err := New(tmpDir)
	require.NoError(t, err)
	return db
}
