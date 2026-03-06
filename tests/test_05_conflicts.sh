#!/usr/bin/env bash
# Test Exercise 5 — Conflicts
# Verifies that a conflict was created and properly resolved on main.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 5 — Conflicts${RESET}"
echo ""

# 5.1 conflict.txt exists in workspace
assert "conflict.txt exists in workspace" ssh_vm "test -f ~/workspace/conflict.txt"

# 5.2 No conflict markers in conflict.txt
conflict_content=$(ssh_vm "cat ~/workspace/conflict.txt")
assert_not_contains "conflict.txt has no <<<<<<<" "$conflict_content" "<<<<<<<"
assert_not_contains "conflict.txt has no >>>>>>>" "$conflict_content" ">>>>>>>"
assert_not_contains "conflict.txt has no =======" "$conflict_content" "^=======$"

# 5.3 conflict.txt has actual content (was resolved)
assert_contains "conflict.txt has resolved content" "$conflict_content" ".+"

# 5.4 A commit with 'resolve' exists on main
resolve_commit=$(ssh_vm "cd ~/workspace && git log --oneline main | grep -i resolve || true")
assert_contains "main has a resolve/merge commit for conflict" "$resolve_commit" "resolve|Merge"

# 5.5 feature/conflict branch exists (was the source of the conflict)
remote_branches=$(ssh_vm "cd ~/workspace && git branch -r")
assert_contains "feature/conflict branch exists on remote" "$remote_branches" "origin/feature/conflict"

# 5.6 git status is clean (conflict fully resolved)
status_out=$(ssh_vm "cd ~/workspace && git checkout main 2>&1 && git status")
assert_contains "working tree is clean after conflict resolution" "$status_out" "nothing to commit|clean"

report_results "Exercise 5"
