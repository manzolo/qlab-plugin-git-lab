#!/usr/bin/env bash
# Common helpers for git-lab test suite
# Sourced by each test script — not executed directly.

set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────────
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# ── Counters ────────────────────────────────────────────────────────
PASS_COUNT=0
FAIL_COUNT=0

# ── Logging ─────────────────────────────────────────────────────────
log_ok()   { printf "${GREEN}  [PASS]${RESET} %s\n" "$*"; }
log_fail() { printf "${RED}  [FAIL]${RESET} %s\n" "$*"; }
log_info() { printf "${YELLOW}  [INFO]${RESET} %s\n" "$*"; }

# ── Assertions ──────────────────────────────────────────────────────
assert() {
    local description="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        log_ok "$description"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        log_fail "$description"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

assert_fail() {
    local description="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        log_fail "$description"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        log_ok "$description"
        PASS_COUNT=$((PASS_COUNT + 1))
    fi
}

assert_contains() {
    local description="$1"
    local output="$2"
    local pattern="$3"
    if echo "$output" | grep -qE "$pattern"; then
        log_ok "$description"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        log_fail "$description (expected pattern: $pattern)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

assert_not_contains() {
    local description="$1"
    local output="$2"
    local pattern="$3"
    if echo "$output" | grep -qE "$pattern"; then
        log_fail "$description (unexpected pattern: $pattern)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        log_ok "$description"
        PASS_COUNT=$((PASS_COUNT + 1))
    fi
}

# ── Workspace detection ─────────────────────────────────────────────
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"

# Find the qlab workspace — walk up until we find .qlab/
_find_workspace() {
    local dir="$PLUGIN_DIR"
    if [[ -d "$dir/../../.qlab" ]]; then
        echo "$(cd "$dir/../.." && pwd)"
        return
    fi
    local d="$dir"
    while [[ "$d" != "/" ]]; do
        if [[ -d "$d/.qlab" ]]; then
            echo "$d"
            return
        fi
        d="$(dirname "$d")"
    done
    echo ""
}

WORKSPACE_DIR="$(_find_workspace)"
if [[ -z "$WORKSPACE_DIR" ]]; then
    echo "ERROR: Cannot find qlab workspace (.qlab/ directory). Make sure the VM is running."
    exit 1
fi

STATE_DIR="$WORKSPACE_DIR/.qlab/state"
SSH_KEY="$WORKSPACE_DIR/.qlab/ssh/qlab_id_rsa"

# ── Port discovery ──────────────────────────────────────────────────
_get_port() {
    local vm_name="$1"
    local port_file="$STATE_DIR/${vm_name}.port"
    if [[ -f "$port_file" ]]; then
        cat "$port_file"
    else
        echo ""
    fi
}

SERVER_PORT="$(_get_port git-lab)"

if [[ -z "$SERVER_PORT" ]]; then
    echo "ERROR: Cannot find VM port. Is git-lab running?"
    echo "  Run: qlab run git-lab"
    exit 1
fi

# ── SSH helpers ─────────────────────────────────────────────────────
_ssh_base_opts=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)

ssh_vm() {
    ssh "${_ssh_base_opts[@]}" -i "$SSH_KEY" -p "$SERVER_PORT" labuser@localhost "$@"
}

# ── Git reset helper ────────────────────────────────────────────────
reset_git() {
    log_info "Resetting git-lab workspace..."
    ssh_vm "bash ~/reset-git-lab.sh" >/dev/null 2>&1 || true
}

# ── Test result reporting ───────────────────────────────────────────
report_results() {
    local test_name="${1:-Test}"
    echo ""
    if [[ "$FAIL_COUNT" -eq 0 ]]; then
        printf "${GREEN}${BOLD}  %s: All %d checks passed${RESET}\n" "$test_name" "$PASS_COUNT"
    else
        printf "${RED}${BOLD}  %s: %d passed, %d failed${RESET}\n" "$test_name" "$PASS_COUNT" "$FAIL_COUNT"
    fi
    return "$FAIL_COUNT"
}
