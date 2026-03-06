#!/usr/bin/env bash
# Test Exercise 6 — Stash
# Verifies git stash works: save dirty state, list, pop, and restore file.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 6 — Stash${RESET}"
echo ""

# 6.1 git stash command is available
assert "git stash subcommand is available" ssh_vm "git stash --help"

# 6.2 Switch to feature/stash and create a dirty file
ssh_vm "cd ~/workspace && git checkout feature/stash 2>/dev/null" >/dev/null 2>&1 || true

# 6.3 Create a dirty tracked+modified file to stash
ssh_vm "echo 'temporary work' >> ~/workspace/wip.txt" >/dev/null

# 6.4 Stash the dirty file (wip.txt is tracked so no -u needed)
ssh_vm "cd ~/workspace && git stash push -m 'test: stash exercise'" >/dev/null
stash_list=$(ssh_vm "cd ~/workspace && git stash list")
assert_contains "stash list is not empty after push" "$stash_list" "stash@"

# 6.5 wip.txt is reset to committed version after stash (modification gone)
wip_after_stash=$(ssh_vm "cat ~/workspace/wip.txt")
assert_not_contains "stash hid the temporary modification" "$wip_after_stash" "temporary work"

# 6.6 Pop the stash
ssh_vm "cd ~/workspace && git stash pop" >/dev/null

# 6.7 Modification is restored after stash pop
wip_after_pop=$(ssh_vm "cat ~/workspace/wip.txt")
assert_contains "temporary modification restored after stash pop" "$wip_after_pop" "temporary work"

# 6.8 Clean up: reset wip.txt to committed state
ssh_vm "cd ~/workspace && git checkout -- wip.txt" >/dev/null

# 6.9 wip.txt was committed on feature/stash (from setup)
wip_log=$(ssh_vm "cd ~/workspace && git log --oneline feature/stash -- wip.txt")
assert_contains "wip.txt was committed on feature/stash" "$wip_log" "."

report_results "Exercise 6"
