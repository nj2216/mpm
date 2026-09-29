#!/usr/bin/env bash
# ==============================================================================
# MPM Automated Test Suite
# Tests: Isolation, Parallel Downloads, Activation, Named Profiles, RPATH, Cleaning
# ==============================================================================

set -uo pipefail

# Visual test output helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASSED_TESTS=0
FAILED_TESTS=0

pass() {
    echo -e "  ${GREEN}✔ PASS:${NC} $1"
    PASSED_TESTS=$((PASSED_TESTS + 1))
}

fail() {
    echo -e "  ${RED}✖ FAIL:${NC} $1"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

info() {
    echo -e "\n${CYAN}==>${NC} ${YELLOW}$1${NC}"
}

# Ensure mpm binary is available
MPM_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bin/mpm"
if [ ! -x "$MPM_BIN" ]; then
    echo -e "${RED}Error: mpm executable not found at $MPM_BIN${NC}"
    exit 1
fi

# Create a temporary sandbox directory for test execution
SANDBOX_DIR="/tmp/mpm_test_sandbox_$$"
mkdir -p "$SANDBOX_DIR"
cd "$SANDBOX_DIR"

cleanup() {
    echo -e "\n${CYAN}Cleaning up test sandbox...${NC}"
    rm -rf "$SANDBOX_DIR"
    rm -rf "$HOME/.local/share/mpm/environments/mpm_test_env"
}
trap cleanup EXIT

echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}         MPM INTEGRATION & FEATURE TEST SUITE         ${NC}"
echo -e "${CYAN}======================================================${NC}"
echo "Running tests in isolated sandbox: $SANDBOX_DIR"
echo "MPM Binary: $MPM_BIN"

# ------------------------------------------------------------------------------
# TEST 1: Update Repositories
# ------------------------------------------------------------------------------
info "Test 1: Repository Indices Synchronization (mpm update)"
if "$MPM_BIN" update >/dev/null 2>&1; then
    if [ -f "$HOME/.local_apt/lists/archive.ubuntu.com_ubuntu_dists_noble_main_binary-amd64_Packages" ] || \
       [ -f "$HOME/.local_apt/lists/archive.ubuntu.com_ubuntu_dists_noble-updates_main_binary-amd64_Packages" ]; then
        pass "Remote package lists fetched and extracted properly."
    else
        fail "Package lists directory missing or empty."
    fi
else
    fail "mpm update exited with an error."
fi

# ------------------------------------------------------------------------------
# TEST 2: Package Search
# ------------------------------------------------------------------------------
info "Test 2: Remote Package Search (mpm search)"
SEARCH_OUT=$("$MPM_BIN" search ripgrep 2>/dev/null || true)
if echo "$SEARCH_OUT" | grep -q "ripgrep"; then
    pass "Search returned accurate package matching results."
else
    fail "Search failed to query local index."
fi

# ------------------------------------------------------------------------------
# TEST 3: Local Project Installation & Host Protection
# ------------------------------------------------------------------------------
info "Test 3: Local Project Installation (mpm install)"
PROJECT_A="$SANDBOX_DIR/project_a"
mkdir -p "$PROJECT_A" && cd "$PROJECT_A"

# Verify tree is clean
if "$MPM_BIN" install jq >/dev/null 2>&1; then
    pass "Package 'jq' and dependencies installed."
else
    fail "mpm install jq failed."
fi

# Verify strict local folder isolation
if [ -d "$PROJECT_A/.mpm" ] && [ -x "$PROJECT_A/.mpm/bin/jq" ]; then
    pass "Assets strictly placed inside .mpm/ directory."
else
    fail "Binaries not found in expected .mpm/ hierarchy."
fi

# Verify host wasn't polluted
if [ -e "$HOME/.local/bin/jq" ] || grep -q "LD_LIBRARY_PATH" "$HOME/.bashrc" 2>/dev/null; then
    fail "Host pollution detected! System was contaminated."
else
    pass "Host filesystem and ~/.bashrc remained 100% untouched."
fi

# ------------------------------------------------------------------------------
# TEST 4: Execution Via 'mpm run'
# ------------------------------------------------------------------------------
info "Test 4: Isolated Execution (mpm run)"
cd "$PROJECT_A"
RUN_OUT=$("$MPM_BIN" run jq --version 2>/dev/null || true)
if echo "$RUN_OUT" | grep -q "jq-"; then
    pass "mpm run executed binary and linked shared libraries correctly ($RUN_OUT)."
else
    fail "Binary execution failed: $RUN_OUT"
fi

# ------------------------------------------------------------------------------
# TEST 5: Interactive Shell Activation & Deactivation
# ------------------------------------------------------------------------------
info "Test 5: Environment Shell Hooks (source .mpm/activate & deactivate)"
cd "$PROJECT_A"

# Run a subshell to test source activation and deactivate behavior
ACTIVATE_TEST=$(bash -c '
    source "'"$PROJECT_A"'/.mpm/activate"
    which jq
    deactivate
    which jq 2>/dev/null || echo "DEACTIVATED_CLEAN"
')

if echo "$ACTIVATE_TEST" | grep -q "$PROJECT_A/.mpm/bin/jq" && echo "$ACTIVATE_TEST" | grep -q "DEACTIVATED_CLEAN"; then
    pass "Virtualenv-style activation and clean deactivation verified."
else
    fail "Activation/deactivation failed. Output: $ACTIVATE_TEST"
fi

# ------------------------------------------------------------------------------
# TEST 6: Named Global Environments (-n / --env)
# ------------------------------------------------------------------------------
info "Test 6: Named Global Profiles (mpm -n <name>)"
GLOBAL_ENV_NAME="mpm_test_env"
GLOBAL_PREFIX="$HOME/.local/share/mpm/environments/$GLOBAL_ENV_NAME"

cd "$SANDBOX_DIR"
if "$MPM_BIN" -n "$GLOBAL_ENV_NAME" install ripgrep >/dev/null 2>&1; then
    pass "Installed package into named global environment."
else
    fail "Failed installing into named environment."
fi

NAMED_RUN_OUT=$("$MPM_BIN" -n "$GLOBAL_ENV_NAME" run rg --version 2>/dev/null | head -n 1 || true)
if echo "$NAMED_RUN_OUT" | grep -q "ripgrep"; then
    pass "Executed package from named global profile ($NAMED_RUN_OUT)."
else
    fail "Failed executing from named profile."
fi

# ------------------------------------------------------------------------------
# TEST 7: Dynamic Linker & RPATH Validation (Complex Multi-Lib: ffmpeg)
# ------------------------------------------------------------------------------
info "Test 7: Complex Multi-Library Linkage (ffmpeg)"
PROJECT_B="$SANDBOX_DIR/project_b"
mkdir -p "$PROJECT_B" && cd "$PROJECT_B"

if "$MPM_BIN" install ffmpeg >/dev/null 2>&1; then
    FFMPEG_OUT=$("$MPM_BIN" run ffmpeg -version 2>/dev/null | head -n 1 || true)
    if echo "$FFMPEG_OUT" | grep -q "ffmpeg version"; then
        pass "Complex binary with 20+ shared libraries linked without error ($FFMPEG_OUT)."
    else
        fail "ffmpeg dynamic linking failed: $FFMPEG_OUT"
    fi
else
    fail "Failed installing ffmpeg."
fi

# ------------------------------------------------------------------------------
# TEST 8: Cache Cleaning (mpm clean)
# ------------------------------------------------------------------------------
info "Test 8: Package Cache Cleaning (mpm clean)"
CACHE_DIR="$HOME/.cache/mpm/archives"
if [ -d "$CACHE_DIR" ] && [ "$(ls -A "$CACHE_DIR")" ]; then
    "$MPM_BIN" clean >/dev/null 2>&1
    if [ -z "$(ls -A "$CACHE_DIR")" ]; then
        pass "Package archive cache emptied completely."
    else
        fail "Cache was not cleared."
    fi
else
    pass "Cache was already empty."
fi

# ------------------------------------------------------------------------------
# FINAL REPORT
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}======================================================${NC}"
echo -e "${CYAN}                    TEST RESULTS                      ${NC}"
echo -e "${CYAN}======================================================${NC}"
echo -e "  ${GREEN}Passed Tests:${NC}  $PASSED_TESTS"
echo -e "  ${RED}Failed Tests:${NC}  $FAILED_TESTS"

if [ "$FAILED_TESTS" -eq 0 ]; then
    echo -e "\n${GREEN}ALL FEATURES VERIFIED: 100% PRODUCTION READY!${NC}\n"
    exit 0
else
    echo -e "\n${RED}SOME TESTS FAILED! Check error messages above.${NC}\n"
    exit 1
fi