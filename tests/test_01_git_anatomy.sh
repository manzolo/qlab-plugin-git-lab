#!/usr/bin/env bash
# Test Exercise 1 — Git Anatomy
# Verifies git is installed, configured, and the workspace repo exists.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 1 — Git Anatomy${RESET}"
echo ""

# 1.1 git is installed
git_version=$(ssh_vm "git --version")
assert_contains "git is installed" "$git_version" "git version"

# 1.2 user.name is configured
git_name=$(ssh_vm "git config --global user.name")
assert_contains "git user.name is set" "$git_name" ".+"

# 1.3 user.email is configured
git_email=$(ssh_vm "git config --global user.email")
assert_contains "git user.email is set" "$git_email" ".+"

# 1.4 workspace directory exists
assert "~/workspace directory exists" ssh_vm "test -d ~/workspace"

# 1.5 .git directory inside workspace
assert "~/workspace/.git exists" ssh_vm "test -d ~/workspace/.git"

# 1.6 git log returns at least one commit
log_out=$(ssh_vm "cd ~/workspace && git log --oneline")
assert_contains "git log has at least one commit" "$log_out" "."

# 1.7 git status reports a clean working tree
status_out=$(ssh_vm "cd ~/workspace && git status")
assert_contains "working tree is clean" "$status_out" "nothing to commit|clean"

report_results "Exercise 1"
