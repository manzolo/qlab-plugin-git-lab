#!/usr/bin/env bash
# Test Exercise 9 — Git Flow
# Verifies the git flow structure: develop, feature, release, tag (git-flow CLI).

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 9 — Git Flow${RESET}"
echo ""

# 9.0 git-flow CLI is installed
assert "git-flow CLI installed" ssh_vm "command -v git-flow"

# 9.1 develop branch exists locally
local_branches=$(ssh_vm "cd ~/workspace && git branch")
assert_contains "develop branch exists" "$local_branches" "develop"

# 9.2 git-flow initialized (config stored in .git/config by AVH edition)
gitflow_develop=$(ssh_vm "cd ~/workspace && git config --get gitflow.branch.develop 2>/dev/null || echo ''")
assert_contains "git-flow initialized (develop configured)" "$gitflow_develop" "develop"

# 9.3 tag v1.0 exists (created by git flow release finish)
tags=$(ssh_vm "cd ~/workspace && git tag")
assert_contains "tag v1.0 exists" "$tags" "v1.0"

# 9.4 tag v1.0 is reachable from main
tagged_commit=$(ssh_vm "cd ~/workspace && git rev-list -n 1 v1.0")
main_commits=$(ssh_vm "cd ~/workspace && git log --format='%H' main")
assert_contains "tag v1.0 is reachable from main" "$main_commits" "$tagged_commit"

# 9.5 develop branch exists on remote
remote_branches=$(ssh_vm "cd ~/workspace && git branch -r")
assert_contains "develop exists on remote" "$remote_branches" "origin/develop"

# 9.6 main has merge commit from release/1.0 (git flow release finish merges and removes the branch)
main_merge_log=$(ssh_vm "cd ~/workspace && git log --oneline --merges main")
assert_contains "main has merge commit from release/1.0" "$main_merge_log" "[Rr]elease.*1\.0|1\.0.*[Rr]elease"

# 9.7 main has a merge commit from release/1.0
main_log=$(ssh_vm "cd ~/workspace && git log --oneline main")
assert_contains "main has release merge commit" "$main_log" "[Rr]elease"

# 9.8 feature/gitflow-demo commit is in develop history (branch deleted by git flow feature finish)
gitflow_demo_log=$(ssh_vm "cd ~/workspace && git log --oneline develop --grep='gitflow-demo'")
assert_contains "feature/gitflow-demo commit in develop history" "$gitflow_demo_log" "gitflow-demo"

# 9.9 gitflow-feature.txt exists in develop
assert "gitflow-feature.txt in develop history" ssh_vm "cd ~/workspace && git show develop:gitflow-feature.txt"

report_results "Exercise 9"
