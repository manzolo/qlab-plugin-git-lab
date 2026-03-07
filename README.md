# git-lab — Git Version Control Lab

[![QLab Plugin](https://img.shields.io/badge/QLab-Plugin-blue)](https://github.com/manzolo/qlab)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey)](https://github.com/manzolo/qlab)

A [QLab](https://github.com/manzolo/qlab) plugin that boots a virtual machine with Git pre-configured and a complete workspace covering everything from basic commits to git flow. The `git-flow` CLI is installed so you can practice the branching model with real commands. The shell is zsh with oh-my-zsh (agnoster theme + git plugin) for a richer Git experience.

## Objectives

- Understand the Git repository anatomy (`.git/`, config, index)
- Stage and create commits with meaningful messages
- Create and switch branches, list local and remote refs
- Merge branches and understand fast-forward vs merge commits
- Detect and resolve merge conflicts
- Save and restore work in progress with `git stash`
- Push, fetch, and pull with a bare remote repository
- Rebase a branch onto another for linear history
- Apply the git flow branching model with the `git-flow` CLI (`git flow init`, `feature start/finish`, `release start/finish`)

## How It Works

1. **Cloud image**: Downloads a minimal Ubuntu 22.04 cloud image (~250 MB)
2. **Cloud-init**: Installs `git`, `git-flow`, `zsh`, oh-my-zsh, creates `labuser`, sets up the workspace
3. **Bare repo**: Creates `/srv/git/lab.git` as the local remote origin
4. **Pre-solved workspace**: `~/workspace` is pre-configured with all exercises completed — tests pass out of the box; reset and redo at any time
5. **QEMU boot**: Starts the VM in background with SSH port forwarding

## Credentials

- **SSH Username:** `labuser`
- **SSH Password:** `labpass`
- **Shell:** `zsh` with oh-my-zsh (agnoster theme, git plugin)

## Ports

| Service | Host Port | VM Port |
|---------|-----------|---------|
| SSH     | dynamic   | 22      |

> The host SSH port is dynamically allocated. Use `qlab ports` to see the actual mapping.

## Usage

```bash
# Install the plugin
qlab install git-lab

# Run the lab (wait ~120s for boot + git workspace setup)
qlab run git-lab

# Connect via SSH — drops directly into ~/workspace
qlab shell git-lab

# Inside the VM:
git log --oneline --graph --all   # full history
git branch -a                     # all branches
git tag                           # list tags

# Run automated tests
qlab test git-lab

# Stop the VM
qlab stop git-lab
```

## Exercises

> **New to Git?** See the [Step-by-Step Guide](guide.md) for theory, explore commands, and practice walkthroughs for each topic.

| # | Exercise | What you will do |
|---|----------|-----------------|
| 1 | **Git Anatomy** | Explore `.git/`, check global config, verify repository structure |
| 2 | **Commits** | Inspect history with `git log`, examine commit objects with `git show` |
| 3 | **Branches** | List local and remote branches, understand pointers |
| 4 | **Merge** | See how feature/hello was merged into main, read merge commits |
| 5 | **Conflicts** | Inspect `conflict.txt`, find the resolution commit, replay the conflict |
| 6 | **Stash** | Stash a modification on `feature/stash`, pop it back, commit |
| 7 | **Remote** | Explore the bare repo, run `git fetch`, compare local vs origin |
| 8 | **Rebase** | Verify the linear history of `feature/stash` rebased onto main |
| 9 | **Git Flow** | Use `git flow init`, `feature start/finish`, `release start/finish`; explore develop, release/1.0, tag v1.0 |

## Reset an Exercise

The workspace is pre-solved. To wipe everything and start from scratch:

```bash
# Inside the VM:
bash ~/reset-git-lab.sh

# Then redo any exercise manually from ~/workspace
```

To reset the entire lab from the host:

```bash
qlab stop git-lab
qlab run git-lab
```

## Automated Tests

A test suite validates each exercise against the running VM:

```bash
# Start the lab first
qlab run git-lab
# Wait ~120s for cloud-init + git setup, then:
qlab test git-lab
```

All 9 exercises are tested automatically (Exercise 9 includes a check for the `git-flow` CLI). Expected output:

```
  Exercises run:     9
  Exercises passed:  9
  Exercises failed:  0
  All exercises passed!
```

## zsh + oh-my-zsh Git Integration

The shell is configured with:

- **Theme**: `agnoster` — shows `user@host path git:(branch) ✗` in the prompt
- **Plugin**: `git` — provides aliases like `gst` (`git status`), `gco` (`git checkout`), `gcmsg` (`git commit -m`), `glog` (`git log --oneline --graph`), `gd` (`git diff`)

> The agnoster theme requires Powerline-patched fonts on your terminal emulator. Install a Nerd Font (e.g. MesloLGS NF, Fira Code Nerd Font) if you see garbled characters.
