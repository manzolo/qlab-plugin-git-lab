#!/usr/bin/env bash
# git-lab run script — boots a VM with Git pre-configured for all exercises

set -euo pipefail

PLUGIN_NAME="git-lab"

echo "============================================="
echo "  git-lab: Git Version Control Lab"
echo "============================================="
echo ""
echo "  This lab demonstrates:"
echo "    1. Git anatomy: repository structure and config"
echo "    2. Commits: staging, history, and messages"
echo "    3. Branches: creation, switching, and listing"
echo "    4. Merge: fast-forward and merge commits"
echo "    5. Conflicts: detection and resolution"
echo "    6. Stash: saving and restoring work in progress"
echo "    7. Remote: push, pull, fetch with a bare repo"
echo "    8. Rebase: linear history via rebase"
echo "    9. Git flow: develop, feature, release, tag"
echo ""

# Source QLab core libraries
if [[ -z "${QLAB_ROOT:-}" ]]; then
    echo "ERROR: QLAB_ROOT not set. Run this plugin via 'qlab run ${PLUGIN_NAME}'."
    exit 1
fi

for lib_file in "$QLAB_ROOT"/lib/*.bash; do
    # shellcheck source=/dev/null
    [[ -f "$lib_file" ]] && source "$lib_file"
done

# Configuration
WORKSPACE_DIR="${WORKSPACE_DIR:-.qlab}"
LAB_DIR="lab"
IMAGE_DIR="$WORKSPACE_DIR/images"
CLOUD_IMAGE_URL=$(get_config CLOUD_IMAGE_URL "https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64.img")
CLOUD_IMAGE_FILE="$IMAGE_DIR/ubuntu-22.04-minimal-cloudimg-amd64.img"
MEMORY="${QLAB_MEMORY:-$(get_config DEFAULT_MEMORY 1024)}"

# Ensure directories exist
mkdir -p "$LAB_DIR" "$IMAGE_DIR"

# Step 1: Download cloud image if not present
info "Step 1: Cloud image"
if [[ -f "$CLOUD_IMAGE_FILE" ]]; then
    success "Cloud image already downloaded: $CLOUD_IMAGE_FILE"
else
    echo ""
    echo "  Cloud images are pre-built OS images designed for cloud environments."
    echo "  They are minimal and expect cloud-init to configure them on first boot."
    echo ""
    info "Downloading Ubuntu cloud image..."
    echo "  URL: $CLOUD_IMAGE_URL"
    echo "  This may take a few minutes depending on your connection."
    echo ""
    check_dependency curl || exit 1
    curl -L -o "$CLOUD_IMAGE_FILE" "$CLOUD_IMAGE_URL" || {
        error "Failed to download cloud image."
        echo "  Check your internet connection and try again."
        exit 1
    }
    success "Cloud image downloaded: $CLOUD_IMAGE_FILE"
fi
echo ""

# Step 2: Create cloud-init configuration
info "Step 2: Cloud-init configuration"
echo ""
echo "  cloud-init will:"
echo "    - Create user 'labuser' with SSH access"
echo "    - Install git"
echo "    - Pre-configure a complete git workspace with all exercises solved"
echo "    - Set up a bare repo at /srv/git/lab.git as the remote origin"
echo ""

cat > "$LAB_DIR/user-data" <<'USERDATA'
#cloud-config
hostname: git-lab
package_update: true
users:
  - name: labuser
    plain_text_passwd: labpass
    lock_passwd: false
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - "__QLAB_SSH_PUB_KEY__"
ssh_pwauth: true
packages:
  - git
  - zsh
  - fonts-powerline
write_files:
  - path: /etc/profile.d/cloud-init-status.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      if command -v cloud-init >/dev/null 2>&1; then
        status=$(cloud-init status 2>/dev/null)
        if echo "$status" | grep -q "running"; then
          printf '\033[1;33m'
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "  Cloud-init is still running..."
          echo "  Some packages and services may not be ready yet."
          echo "  Run 'cloud-init status --wait' to wait for completion."
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          printf '\033[0m\n'
        fi
      fi
  - path: /etc/motd.raw
    content: |
      \033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m
        \033[1;32mgit-lab\033[0m — \033[1mGit Version Control Lab\033[0m
      \033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m

        \033[1;33mExercises:\033[0m
          01 - Git anatomy      \033[0;32mcd ~/workspace && git log --oneline\033[0m
          02 - Commits          \033[0;32mgit log --oneline\033[0m
          03 - Branches         \033[0;32mgit branch -a\033[0m
          04 - Merge            \033[0;32mgit log --merges\033[0m
          05 - Conflicts        \033[0;32mcat conflict.txt\033[0m
          06 - Stash            \033[0;32mgit stash list\033[0m
          07 - Remote           \033[0;32mgit remote -v\033[0m
          08 - Rebase           \033[0;32mgit log --oneline feature/stash\033[0m
          09 - Git flow         \033[0;32mgit tag\033[0m

        \033[1;33mKey paths:\033[0m
          \033[0;32m~/workspace\033[0m       working directory
          \033[0;32m/srv/git/lab.git\033[0m  bare remote repository

        \033[1;33mReset an exercise:\033[0m
          \033[0;32mbash ~/reset-git-lab.sh\033[0m   rebuild from scratch

        \033[1;33mCredentials:\033[0m  \033[1;36mlabuser\033[0m / \033[1;36mlabpass\033[0m
        \033[1;33mExit:\033[0m         type '\033[1;31mexit\033[0m'

      \033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m

  - path: /tmp/setup-git-lab.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -euo pipefail

      echo "=== Setting up git-lab workspace ==="

      # Global git config
      git config --global user.name "Lab User"
      git config --global user.email "labuser@git-lab.local"
      git config --global init.defaultBranch main

      # Bare remote repository
      sudo mkdir -p /srv/git
      sudo git init --bare /srv/git/lab.git
      sudo chown -R labuser:labuser /srv/git

      # Working directory
      rm -rf ~/workspace
      mkdir -p ~/workspace
      cd ~/workspace
      git init
      git remote add origin /srv/git/lab.git

      # ── Exercise 2: base commits ───────────────────────────────────
      echo "# Git Lab" > README.md
      git add README.md
      git commit -m "Initial commit: add README"

      echo "Hello, Git!" > hello.txt
      git add hello.txt
      git commit -m "Add hello.txt"

      echo "version=1.0" > version.txt
      git add version.txt
      git commit -m "Add version.txt"

      git push -u origin main

      # ── Exercise 3 & 4: feature/hello branch + merge ───────────────
      git checkout -b feature/hello
      echo "Hello from feature branch!" >> hello.txt
      git add hello.txt
      git commit -m "feature/hello: add greeting line"
      git push origin feature/hello

      git checkout main
      git merge feature/hello -m "Merge feature/hello into main"
      git push origin main

      # ── Exercise 5: conflict scenario ──────────────────────────────
      git checkout -b feature/conflict
      echo "This is the feature version" > conflict.txt
      git add conflict.txt
      git commit -m "feature/conflict: add conflict.txt"
      git push origin feature/conflict

      git checkout main
      echo "This is the main version" > conflict.txt
      git add conflict.txt
      git commit -m "main: add conflict.txt"

      # Intentionally trigger and resolve a merge conflict
      git merge feature/conflict || true
      echo "Resolved: combined content from feature and main" > conflict.txt
      git add conflict.txt
      git commit -m "Merge: resolve conflict.txt conflict"
      git push origin main

      # ── Exercise 6: stash demo ─────────────────────────────────────
      git checkout -b feature/stash

      # Create and commit an initial tracked file
      echo "Initial content" > wip.txt
      git add wip.txt
      git commit -m "feature/stash: initial wip.txt"
      git push origin feature/stash

      # Demonstrate stash on a tracked-but-modified file
      echo "Work in progress content" >> wip.txt
      git stash push -m "WIP: stash demo"
      # Pop stash and commit the final version
      git stash pop
      git add wip.txt
      git commit -m "feature/stash: finalize wip.txt after stash demo"
      git push origin feature/stash

      # ── Exercise 8: hotfix on main + rebase ────────────────────────
      git checkout main
      echo "hotfix=true" >> version.txt
      git add version.txt
      git commit -m "hotfix: update version.txt"
      git push origin main

      git checkout feature/stash
      git rebase main
      git push --force origin feature/stash

      # ── Exercise 9: git flow ───────────────────────────────────────
      git checkout main
      git checkout -b develop
      git push origin develop

      git checkout -b feature/gitflow-demo
      echo "Git flow feature content" > gitflow-feature.txt
      git add gitflow-feature.txt
      git commit -m "feature/gitflow-demo: add feature content"
      git push origin feature/gitflow-demo

      git checkout develop
      git merge feature/gitflow-demo --no-ff -m "Merge feature/gitflow-demo into develop"
      git push origin develop

      git checkout -b release/1.0
      echo "" >> README.md
      echo "## Release 1.0" >> README.md
      git add README.md
      git commit -m "release/1.0: prepare release notes"
      git push origin release/1.0

      git checkout main
      git merge release/1.0 --no-ff -m "Merge release/1.0 into main"
      git tag -a v1.0 -m "Release version 1.0"
      git push origin main
      git push origin v1.0

      # Leave workspace on main in a clean state
      git checkout main
      git fetch origin

      # ── oh-my-zsh with git plugin + agnoster theme ─────────────────
      RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
      sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' ~/.zshrc
      sed -i 's/^plugins=(.*)/plugins=(git)/' ~/.zshrc
      echo 'cd ~/workspace 2>/dev/null || true' >> ~/.zshrc

      echo "=== git-lab setup complete ==="

  - path: /tmp/reset-git-lab.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      echo "Resetting git-lab workspace..."
      sudo rm -rf /srv/git/lab.git
      bash ~/setup-git-lab.sh
      echo "Done. cd ~/workspace to start fresh."

runcmd:
  - chmod -x /etc/update-motd.d/*
  - sed -i 's/^#\?PrintMotd.*/PrintMotd yes/' /etc/ssh/sshd_config
  - sed -i 's/^session.*pam_motd.*/# &/' /etc/pam.d/sshd
  - printf '%b\n' "$(cat /etc/motd.raw)" > /etc/motd
  - rm -f /etc/motd.raw
  - systemctl restart sshd
  - cp /tmp/setup-git-lab.sh /home/labuser/setup-git-lab.sh
  - cp /tmp/reset-git-lab.sh /home/labuser/reset-git-lab.sh
  - chown labuser:labuser /home/labuser/setup-git-lab.sh /home/labuser/reset-git-lab.sh
  - sudo -Hu labuser bash /home/labuser/setup-git-lab.sh
  - chsh -s /usr/bin/zsh labuser
  - echo "=== git-lab VM is ready! ==="
USERDATA

# Inject the SSH public key into user-data
sed -i "s|__QLAB_SSH_PUB_KEY__|${QLAB_SSH_PUB_KEY:-}|g" "$LAB_DIR/user-data"

cat > "$LAB_DIR/meta-data" <<METADATA
instance-id: ${PLUGIN_NAME}-001
local-hostname: ${PLUGIN_NAME}
METADATA

success "Created cloud-init files in $LAB_DIR/"
echo ""

# Step 3: Generate cloud-init ISO
info "Step 3: Cloud-init ISO"
echo ""
echo "  QEMU reads cloud-init data from a small ISO image (CD-ROM)."
echo "  We use genisoimage to create it with the 'cidata' volume label."
echo ""

CIDATA_ISO="$LAB_DIR/cidata.iso"
check_dependency genisoimage || {
    warn "genisoimage not found. Install it with: sudo apt install genisoimage"
    exit 1
}
genisoimage -output "$CIDATA_ISO" -volid cidata -joliet -rock \
    "$LAB_DIR/user-data" "$LAB_DIR/meta-data" 2>/dev/null
success "Created cloud-init ISO: $CIDATA_ISO"
echo ""

# Step 4: Create overlay disk
info "Step 4: Overlay disk"
echo ""
echo "  An overlay disk uses copy-on-write (COW) on top of the base image."
echo "  This means:"
echo "    - The original cloud image stays untouched"
echo "    - All writes go to the overlay file"
echo "    - You can reset the lab by deleting the overlay"
echo ""

OVERLAY_DISK="$LAB_DIR/${PLUGIN_NAME}-disk.qcow2"
if [[ -f "$OVERLAY_DISK" ]]; then
    info "Removing previous overlay disk..."
    rm -f "$OVERLAY_DISK"
fi
create_overlay "$CLOUD_IMAGE_FILE" "$OVERLAY_DISK" "${QLAB_DISK_SIZE:-}" || {
    error "Failed to create overlay disk."
    exit 1
}
echo ""

# Step 5: Boot the VM in background (SSH only)
info "Step 5: Starting VM in background"
echo ""
echo "  The VM will run in background with:"
echo "    - Serial output logged to .qlab/logs/$PLUGIN_NAME.log"
echo "    - SSH access on a dynamically allocated port"
echo ""

start_vm "$OVERLAY_DISK" "$CIDATA_ISO" "$MEMORY" "$PLUGIN_NAME" auto

echo ""
echo "============================================="
echo "  git-lab: VM is booting"
echo "============================================="
echo ""
echo "  Credentials:"
echo "    Username: labuser"
echo "    Password: labpass"
echo ""
echo "  Connect via SSH (wait ~90s for boot + git setup):"
echo "    qlab shell ${PLUGIN_NAME}"
echo ""
echo "  View boot log:"
echo "    qlab log ${PLUGIN_NAME}"
echo ""
echo "  Run automated tests:"
echo "    qlab test ${PLUGIN_NAME}"
echo ""
echo "  Stop VM:"
echo "    qlab stop ${PLUGIN_NAME}"
echo ""
echo "  Tip: override resources with environment variables:"
echo "    QLAB_MEMORY=2048 qlab run ${PLUGIN_NAME}"
echo "============================================="
