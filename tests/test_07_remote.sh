#!/usr/bin/env bash
# Test Exercise 7 — Remote
# Verifies the remote origin is configured and the bare repo has objects.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 7 — Remote${RESET}"
echo ""

# 7.1 remote origin is configured
remote_v=$(ssh_vm "cd ~/workspace && git remote -v")
assert_contains "origin remote is configured" "$remote_v" "origin"

# 7.2 origin points to the local bare repo
assert_contains "origin points to /srv/git/lab.git" "$remote_v" "/srv/git/lab.git"

# 7.3 bare repo directory exists
assert "bare repo /srv/git/lab.git exists" ssh_vm "test -d /srv/git/lab.git"

# 7.4 bare repo has objects
objects=$(ssh_vm "ls /srv/git/lab.git/objects/")
assert_contains "bare repo has git objects" "$objects" "."

# 7.5 git fetch succeeds
assert "git fetch origin succeeds" ssh_vm "cd ~/workspace && git fetch origin"

# 7.6 origin/main is accessible
origin_main=$(ssh_vm "cd ~/workspace && git log --oneline origin/main")
assert_contains "origin/main has commits" "$origin_main" "."

# 7.7 local main is in sync with origin/main
local_sha=$(ssh_vm "cd ~/workspace && git rev-parse main")
remote_sha=$(ssh_vm "cd ~/workspace && git rev-parse origin/main")
assert_contains "local main matches origin/main" "$local_sha" "$remote_sha"

# 7.8 git ls-remote works
ls_remote=$(ssh_vm "cd ~/workspace && git ls-remote origin")
assert_contains "git ls-remote lists refs" "$ls_remote" "refs/heads/main"

report_results "Exercise 7"
