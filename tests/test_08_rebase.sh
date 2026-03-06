#!/usr/bin/env bash
# Test Exercise 8 — Rebase
# Verifies feature/stash has a linear history on top of main via rebase.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 8 — Rebase${RESET}"
echo ""

# 8.1 feature/stash branch exists
local_branches=$(ssh_vm "cd ~/workspace && git branch")
assert_contains "feature/stash branch exists" "$local_branches" "feature/stash"

# 8.2 feature/stash is ahead of main (has unique commits)
ahead=$(ssh_vm "cd ~/workspace && git log --oneline main..feature/stash | wc -l | tr -d ' '")
assert_contains "feature/stash is ahead of main" "$ahead" "^[1-9]"

# 8.3 History of feature/stash relative to main is linear (no merge commits)
merge_commits=$(ssh_vm "cd ~/workspace && git log --merges main..feature/stash --oneline | wc -l | tr -d ' '")
assert_contains "no merge commits between main and feature/stash (linear history)" "$merge_commits" "^0$"

# 8.4 feature/stash was rebased: its commits come after all main commits
# The parent of the first diverging commit on feature/stash should be in main
diverge_parent=$(ssh_vm "cd ~/workspace && git log --oneline feature/stash --not main | tail -1 | awk '{print \$1}' | xargs git log --pretty='%P' -1 | awk '{print \$1}'")
main_commits=$(ssh_vm "cd ~/workspace && git log --oneline main --format='%H'")
assert_contains "feature/stash base commit is reachable from main" "$main_commits" "$diverge_parent"

# 8.5 wip.txt exists on feature/stash
assert "wip.txt exists on feature/stash" ssh_vm "cd ~/workspace && git show feature/stash:wip.txt"

# 8.6 hotfix commit is reachable from feature/stash (rebase included main changes)
stash_log=$(ssh_vm "cd ~/workspace && git log --oneline feature/stash")
assert_contains "hotfix commit is in feature/stash history" "$stash_log" "hotfix"

report_results "Exercise 8"
