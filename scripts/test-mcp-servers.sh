#!/bin/bash
# Test chonkometer against MCP servers
#
# Usage: ./test-mcp-servers.sh [subset]
#
# Subsets:
#   quick      - 5 popular servers (default)
#   reference  - Official @modelcontextprotocol servers
#   browser    - Browser automation servers
#   thirdparty - Popular third-party servers
#   all        - All available test servers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CKM="$PROJECT_ROOT/ckm"
SUBSET="${1:-quick}"

# Build if needed
if [[ ! -f "$CKM" ]]; then
    echo "Building ckm..."
    (cd "$PROJECT_ROOT" && go build -o ckm ./cmd/ckm)
fi

# Counter for test numbering
COUNT=0

FAILED=0

run_test() {
    local name="$1"
    local cmd="$2"
    COUNT=$((COUNT + 1))
    echo "$COUNT. $name"
    echo "$(printf '%*s' ${#name} '' | tr ' ' '-')---"
    if ! eval "$CKM $cmd"; then
        FAILED=$((FAILED + 1))
        echo "[FAILED]"
    fi
    echo
}

# Server definitions by category
run_quick() {
    run_test "Everything (reference server)" "npx -y @modelcontextprotocol/server-everything"
    run_test "Chrome DevTools (CDP)" "npx -y chrome-devtools-mcp"
    run_test "GitHub" "npx -y @modelcontextprotocol/server-github"
    run_test "Filesystem" "npx -y @modelcontextprotocol/server-filesystem /tmp"
    run_test "Puppeteer" "npx -y @modelcontextprotocol/server-puppeteer"
}

run_reference() {
    run_test "Everything" "npx -y @modelcontextprotocol/server-everything"
    run_test "Filesystem" "npx -y @modelcontextprotocol/server-filesystem /tmp"
    run_test "Memory" "npx -y @modelcontextprotocol/server-memory"
    run_test "Sequential Thinking" "npx -y @modelcontextprotocol/server-sequential-thinking"
    run_test "GitHub" "npx -y @modelcontextprotocol/server-github"
    run_test "Puppeteer" "npx -y @modelcontextprotocol/server-puppeteer"
}

run_browser() {
    run_test "Chrome DevTools (CDP)" "npx -y chrome-devtools-mcp"
    run_test "Puppeteer" "npx -y @modelcontextprotocol/server-puppeteer"
    run_test "Playwright" "npx -y @playwright/mcp"
}

run_thirdparty() {
    run_test "Chrome DevTools (CDP)" "npx -y chrome-devtools-mcp"
    run_test "Playwright" "npx -y @playwright/mcp"
}

run_all() {
    echo "=== Reference Servers ==="
    echo
    run_reference

    echo "=== Third-Party Servers ==="
    echo
    run_thirdparty
}

# Main
echo "Testing chonkometer against MCP servers (subset: $SUBSET)"
echo "=========================================================="
echo

case "$SUBSET" in
    quick)
        run_quick
        ;;
    reference)
        run_reference
        ;;
    browser)
        run_browser
        ;;
    thirdparty)
        run_thirdparty
        ;;
    all)
        run_all
        ;;
    *)
        echo "Unknown subset: $SUBSET"
        echo "Available subsets: quick, reference, browser, thirdparty, all"
        exit 1
        ;;
esac

echo "=========================================================="
if [[ $FAILED -gt 0 ]]; then
    echo "Completed $COUNT tests ($FAILED failed)"
    exit 1
else
    echo "Completed $COUNT tests (all passed)"
fi
