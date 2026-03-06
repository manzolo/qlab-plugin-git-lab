#!/usr/bin/env bash
# Test Exercise 3 — Branches
# Verifies that key branches exist both locally and on the remote.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 3 — Branches${RESET}"
echo ""

# 3.1 feature/hello exists locally
local_branches=$(ssh_vm "cd ~/workspace && git branch")
assert_contains "feature/hello exists locally" "$local_branches" "feature/hello"

# 3.2 feature/hello exists on remote
remote_branches=$(ssh_vm "cd ~/workspace && git branch -r")
assert_contains "feature/hello exists on remote" "$remote_branches" "origin/feature/hello"

# 3.3 develop branch exists locally
assert_contains "develop exists locally" "$local_branches" "develop"

# 3.4 develop exists on remote
assert_contains "develop exists on remote" "$remote_branches" "origin/develop"

# 3.5 feature/stash exists locally
assert_contains "feature/stash exists locally" "$local_branches" "feature/stash"

# 3.6 main exists on remote
assert_contains "main exists on remote" "$remote_branches" "origin/main"

# 3.7 git branch -a lists multiple branches
all_branches=$(ssh_vm "cd ~/workspace && git branch -a | wc -l | tr -d ' '")
assert_contains "repository has multiple branches" "$all_branches" "^[4-9]$|^[0-9]{2,}"

report_results "Exercise 3"
