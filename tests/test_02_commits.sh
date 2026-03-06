#!/usr/bin/env bash
# Test Exercise 2 — Commits
# Verifies the main branch has at least 3 commits with non-empty messages.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 2 — Commits${RESET}"
echo ""

# 2.1 At least 3 commits on main
commit_count=$(ssh_vm "cd ~/workspace && git log --oneline main | wc -l | tr -d ' '")
assert_contains "main has at least 3 commits" "$commit_count" "^[3-9]$|^[0-9]{2,}"

# 2.2 git log --oneline works and shows hashes + messages
log_out=$(ssh_vm "cd ~/workspace && git log --oneline")
assert_contains "git log --oneline shows commit hashes" "$log_out" "^[0-9a-f]"

# 2.3 No empty commit messages
empty_msgs=$(ssh_vm "cd ~/workspace && git log --format='%s' | grep -c '^$' || true")
assert_contains "no empty commit messages" "${empty_msgs:-0}" "^0$"

# 2.4 README.md is tracked
readme_log=$(ssh_vm "cd ~/workspace && git log --oneline -- README.md")
assert_contains "README.md has commits" "$readme_log" "."

# 2.5 hello.txt is tracked
hello_log=$(ssh_vm "cd ~/workspace && git log --oneline -- hello.txt")
assert_contains "hello.txt has commits" "$hello_log" "."

# 2.6 version.txt is tracked
version_log=$(ssh_vm "cd ~/workspace && git log --oneline -- version.txt")
assert_contains "version.txt has commits" "$version_log" "."

report_results "Exercise 2"
