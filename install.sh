#!/usr/bin/env bash
# git-lab install script

set -euo pipefail

echo ""
echo "  [git-lab] Installing..."
echo ""
echo "  This plugin teaches Git version control from basics to advanced topics:"
echo "    - Repository anatomy and configuration"
echo "    - Commits, staging, and history"
echo "    - Branching and merging strategies"
echo "    - Conflict detection and resolution"
echo "    - Stash, rebase, and git flow workflow"
echo ""

# Create lab working directory
mkdir -p lab

# Check for required tools
echo "  Checking dependencies..."
local_ok=true
for cmd in qemu-system-x86_64 qemu-img genisoimage curl; do
    if command -v "$cmd" &>/dev/null; then
        echo "    [OK] $cmd"
    else
        echo "    [!!] $cmd — not found (install before running)"
        local_ok=false
    fi
done

if [[ "$local_ok" == true ]]; then
    echo ""
    echo "  All dependencies are available."
else
    echo ""
    echo "  Some dependencies are missing. Install them with:"
    echo "    sudo apt install qemu-kvm qemu-utils genisoimage curl"
fi

echo ""
echo "  [git-lab] Installation complete."
echo "  Run with: qlab run git-lab"
