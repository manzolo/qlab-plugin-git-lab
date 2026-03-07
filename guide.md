# Git Lab — Learning Guide

## Prerequisites

Start the lab and wait for cloud-init to complete (~90 seconds):

```bash
qlab run git-lab
qlab shell git-lab
```

Once inside the VM, all exercises are pre-solved in `~/workspace`. You can explore the history, reset, and redo any exercise with:

```bash
bash ~/reset-git-lab.sh
```

---

## Exercise 01 — Git Anatomy

### Theory

A git repository is a `.git/` directory that stores the complete history of a project. Key configuration is in `.git/config` (local) or `~/.gitconfig` (global).

### Explore

```bash
cd ~/workspace

# See the repo structure
ls -la .git/

# Check global config
git config --global --list

# Check local repo config
git config --list --local

# Who am I?
git config user.name
git config user.email

# What branch am I on?
git status
git branch
```

### Reset and redo

```bash
bash ~/reset-git-lab.sh
cd ~/workspace
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

---

## Exercise 02 — Commits

### Theory

A commit is a snapshot of the project at a point in time. Every commit has an author, a timestamp, a message, and a parent (except the first). The staging area (index) lets you compose commits carefully.

### Explore

```bash
cd ~/workspace

# Full log
git log

# Compact log
git log --oneline

# Log with graph
git log --oneline --graph --all

# Show a specific commit
git show HEAD

# See what changed between commits
git diff HEAD~1 HEAD
```

### Practice

```bash
# Stage and commit a new file
echo "My notes" > notes.txt
git add notes.txt
git commit -m "Add notes.txt"

# Amend the last commit message (before pushing)
git commit --amend -m "docs: add notes.txt"
```

---

## Exercise 03 — Branches

### Theory

A branch is a movable pointer to a commit. Creating a branch is instant and cheap. Branches let you work on features in isolation without affecting the main codebase.

### Explore

```bash
cd ~/workspace

# List local branches
git branch

# List remote branches
git branch -r

# List all branches
git branch -a

# See which branches are merged into main
git branch --merged main
```

### Practice

```bash
# Create and switch to a new branch
git checkout -b feature/my-feature

# (Modern syntax)
git switch -c feature/my-feature

# Switch back to main
git checkout main

# Delete a merged branch
git branch -d feature/my-feature
```

---

## Exercise 04 — Merge

### Theory

Merging integrates changes from one branch into another. A **fast-forward merge** moves the pointer forward when there is no divergence. A **merge commit** creates an explicit node in history when branches have diverged.

### Explore

```bash
cd ~/workspace

# See merge commits
git log --merges --oneline

# Visualize the graph
git log --oneline --graph --all

# Which branches are merged into main?
git branch --merged main
```

### Practice

```bash
# Create a branch, add a commit, merge it
git checkout -b feature/test-merge
echo "test" > merge-test.txt
git add merge-test.txt
git commit -m "test: add merge-test.txt"

git checkout main
git merge feature/test-merge          # fast-forward
git merge feature/test-merge --no-ff  # force a merge commit
```

---

## Exercise 05 — Conflicts

### Theory

A conflict occurs when two branches modify the same part of the same file. Git marks the conflicting region with markers (`<<<<<<<`, `=======`, `>>>>>>>`). You must resolve conflicts manually, then `git add` and `git commit`.

### Explore

```bash
cd ~/workspace

# See the resolved conflict file
cat conflict.txt

# Find the resolution commit
git log --oneline --grep="resolve"

# See what both branches changed (three-dot diff)
git diff feature/conflict...main -- conflict.txt
```

### Practice

```bash
# Create a conflict manually
git checkout -b branch-a
echo "Version A" > test-conflict.txt
git add test-conflict.txt && git commit -m "branch-a: add test-conflict.txt"

git checkout main
echo "Version B" > test-conflict.txt
git add test-conflict.txt && git commit -m "main: add test-conflict.txt"

git merge branch-a            # this will conflict
# Edit test-conflict.txt to resolve
echo "Resolved version" > test-conflict.txt
git add test-conflict.txt
git commit -m "Merge: resolve test-conflict.txt"
```

---

## Exercise 06 — Stash

### Theory

`git stash` temporarily shelves changes so you can switch context. The stash is a stack — you can push multiple entries and pop them in LIFO order. Stashes are not pushed to remotes.

### Explore

```bash
cd ~/workspace
git checkout feature/stash

# See stash list
git stash list

# See what a stash entry contains
git stash show -p stash@{0}
```

### Practice

```bash
# Modify an existing tracked file (wip.txt is already tracked on feature/stash)
git checkout feature/stash
echo "More work in progress" >> wip.txt

# Stash the tracked modification
git stash push -m "WIP: my in-progress work"

# Verify the working tree is clean (modification is hidden)
git status
cat wip.txt   # shows the committed version, not the WIP

# See the stash
git stash list

# Restore the stash
git stash pop
cat wip.txt   # shows the WIP content again

# Or apply without removing from stack
git stash apply stash@{0}

# Discard a stash entry
git stash drop stash@{0}

# To stash untracked (new) files, use -u:
echo "brand new file" > new-file.txt
git stash push -u -m "WIP: include untracked"
git stash pop
rm new-file.txt
```

---

## Exercise 07 — Remote

### Theory

A **remote** is a reference to another copy of the repository. `git push` uploads local commits; `git fetch` downloads remote changes without modifying the local working tree; `git pull` = `fetch` + `merge`.

In this lab, the remote is a **bare repository** at `/srv/git/lab.git` — a repo without a working tree, suitable as a server.

### Explore

```bash
cd ~/workspace

# See configured remotes
git remote -v

# Inspect the bare repo
ls /srv/git/lab.git/

# Fetch updates from remote
git fetch origin

# Compare local and remote
git log --oneline HEAD..origin/main   # commits on remote not yet local
git log --oneline origin/main..HEAD   # local commits not yet pushed
```

### Practice

```bash
# Create a commit and push
echo "pushed" > pushed.txt
git add pushed.txt && git commit -m "Add pushed.txt"
git push origin main

# Pull changes (if another client had pushed)
git pull origin main

# Track a remote branch
git checkout -b feature/new --track origin/feature/hello
```

---

## Exercise 08 — Rebase

### Theory

`git rebase` re-applies commits from one branch on top of another, creating a **linear history**. Unlike merge, it does not add a merge commit. Use `--force` push after rebasing a shared branch.

**Golden rule:** never rebase commits that have been pushed to a shared branch unless you coordinate with others.

### Explore

```bash
cd ~/workspace

# See the linear history of feature/stash
git log --oneline feature/stash

# Compare with main — no merge commits between them
git log --merges main..feature/stash --oneline

# Visualize the entire graph
git log --oneline --graph --all
```

### Practice

```bash
# Create a new branch from an old point
git checkout main~2 -b feature/rebase-demo
echo "old base" > rebase-demo.txt
git add rebase-demo.txt && git commit -m "demo commit"

# Rebase it onto main
git rebase main

# Interactive rebase to squash commits
git rebase -i HEAD~3
```

---

## Exercise 09 — Git Flow

### Theory

> **Note (Ubuntu AVH edition):** `git flow init` stores its configuration inside `.git/config` (not a separate `.gitflow` file). `git flow feature finish` and `git flow release finish` automatically delete both the local and remote branch after merging.

**Git Flow** is a branching model with defined roles for branches:
- `main` — production-ready code
- `develop` — integration branch
- `feature/*` — new features (branch from develop, merge back into develop)
- `release/*` — release preparation (branch from develop, merge into both main and develop)
- `hotfix/*` — urgent fixes (branch from main, merge into both main and develop)

Tags (`v1.0`) mark release points on `main`.

The `git-flow` CLI automates the branch creation, merging, tagging, and deletion steps. It reads its configuration from the `.gitflow` file at the root of the repository.

### Explore

```bash
cd ~/workspace

# Check git-flow version and that it is installed
git flow version

# See the git-flow configuration (branch names, prefixes)
cat .gitflow

# See the full git flow graph
git log --oneline --graph --all

# List tags
git tag

# Show tag details
git show v1.0

# See develop history
git log --oneline develop
```

### Practice — full git flow cycle with git-flow CLI

```bash
cd ~/workspace

# (Already initialized in this lab — shown for reference)
# git flow init -d
# git config gitflow.prefix.versiontag v

# ── Feature ──────────────────────────────────────────────────
# Start a feature branch from develop
git flow feature start my-feature

echo "new feature" > my-feature.txt
git add my-feature.txt && git commit -m "feature/my-feature: implement feature"

# Finish: merges feature/my-feature into develop, deletes local branch
GIT_MERGE_AUTOEDIT=no git flow feature finish my-feature
git push origin develop

# ── Release ──────────────────────────────────────────────────
# Start a release branch from develop
git flow release start 2.0

echo "## Release 2.0" >> README.md
git add README.md && git commit -m "release/2.0: prepare release"

# Push the release branch to remote before finishing
git push origin release/2.0

# Finish: merges into main AND develop, creates tag v2.0, deletes local branch
GIT_MERGE_AUTOEDIT=no git flow release finish -m "Release version 2.0" 2.0
git push origin main develop
git push origin v2.0

# ── Hotfix ───────────────────────────────────────────────────
# Start a hotfix from main
git flow hotfix start fix-typo

echo "typo fixed" >> README.md
git add README.md && git commit -m "hotfix/fix-typo: fix typo in README"

# Finish: merges into main AND develop, creates tag, deletes local branch
GIT_MERGE_AUTOEDIT=no git flow hotfix finish -m "Hotfix fix-typo" fix-typo
git push origin main develop
git push origin --tags
```

### Quick reference

| Command | What it does |
|---------|-------------|
| `git flow init -d` | Initialize git-flow with default branch names |
| `git flow feature start <name>` | Create `feature/<name>` from develop |
| `git flow feature finish <name>` | Merge feature into develop, delete branch |
| `git flow release start <ver>` | Create `release/<ver>` from develop |
| `git flow release finish <ver>` | Merge into main+develop, tag, delete branch |
| `git flow hotfix start <name>` | Create `hotfix/<name>` from main |
| `git flow hotfix finish <name>` | Merge into main+develop, tag, delete branch |

---

## Running Automated Tests

```bash
# From the host machine:
qlab test git-lab

# Or inside the VM, from the plugin directory:
bash tests/run_all.sh
```
