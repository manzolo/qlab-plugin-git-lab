#!/usr/bin/env bash
# Test Exercise 4 — Merge
# Verifies that feature/hello was merged into main and no unmerged state remains.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 4 — Merge${RESET}"
echo ""

# 4.1 feature/hello is merged into main (appears in merged list)
merged=$(ssh_vm "cd ~/workspace && git branch --merged main")
assert_contains "feature/hello is merged into main" "$merged" "feature/hello"

# 4.2 hello.txt contains the feature branch content (merge was effective)
hello_content=$(ssh_vm "cd ~/workspace && cat hello.txt")
assert_contains "hello.txt contains feature branch line" "$hello_content" "Hello from feature branch"

# 4.3 No unmerged files in the workspace
status_out=$(ssh_vm "cd ~/workspace && git status")
assert_not_contains "no unmerged paths in status" "$status_out" "Unmerged paths|both modified|both added"

# 4.4 main log contains a merge-related entry (merge commit or feature commit)
main_log=$(ssh_vm "cd ~/workspace && git log --oneline main")
assert_contains "main log contains hello-related commit" "$main_log" "hello|Merge"

# 4.5 git status is clean on main
main_status=$(ssh_vm "cd ~/workspace && git checkout main 2>&1 && git status")
assert_contains "main branch is clean after checkout" "$main_status" "nothing to commit|clean"

report_results "Exercise 4"
