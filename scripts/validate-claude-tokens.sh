#!/bin/bash
# Validate chonkometer token counts against Claude's official tokenizer
#
# This script compares tiktoken (cl100k_base) counts from ckm against
# the Vertex AI Claude count-tokens API to measure accuracy.
#
# Requirements:
#   - gcloud CLI authenticated with Vertex AI access
#   - npx (for running MCP servers)
#   - jq (for JSON parsing)
#
# Usage:
#   ./validate-claude-tokens.sh [mcp-server-command...]
#
# Examples:
#   ./validate-claude-tokens.sh                                    # Uses default test server
#   ./validate-claude-tokens.sh npx -y @modelcontextprotocol/server-memory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CKM="$PROJECT_ROOT/ckm"

# Vertex AI settings
LOCATION="us-east5"
MODEL="claude-3-haiku@20240307"

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No colour

# Check dependencies
check_deps() {
    local missing=()

    if ! command -v gcloud &> /dev/null; then
        missing+=("gcloud")
    fi

    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi

    if ! command -v npx &> /dev/null; then
        missing+=("npx")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Missing dependencies: ${missing[*]}${NC}"
        exit 1
    fi

    # Check gcloud auth
    if ! gcloud auth print-access-token &> /dev/null; then
        echo -e "${RED}gcloud not authenticated. Run: gcloud auth login${NC}"
        exit 1
    fi

    # Get project ID
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [[ -z "$PROJECT_ID" ]]; then
        echo -e "${RED}No gcloud project set. Run: gcloud config set project PROJECT_ID${NC}"
        exit 1
    fi
}

# Build ckm if needed
build_ckm() {
    if [[ ! -f "$CKM" ]] || [[ "$PROJECT_ROOT/cmd/ckm/main.go" -nt "$CKM" ]]; then
        echo -e "${BLUE}Building ckm...${NC}"
        (cd "$PROJECT_ROOT" && go build -o ckm ./cmd/ckm)
    fi
}

# Count tokens using Claude API
count_claude_tokens() {
    local content="$1"
    local token
    token=$(gcloud auth print-access-token)

    local response
    response=$(curl -s -X POST \
        "https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/publishers/anthropic/models/count-tokens:rawPredict" \
        -H "Authorization: Bearer ${token}" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"${MODEL}\",
            \"messages\": [{
                \"role\": \"user\",
                \"content\": $(echo "$content" | jq -Rs .)
            }]
        }" 2>/dev/null)

    echo "$response" | jq -r '.input_tokens // "error"'
}

# Main validation
validate() {
    local cmd=("$@")

    echo -e "${BLUE}Running: ckm --json ${cmd[*]}${NC}"
    echo

    # Get JSON output from ckm
    local json_output
    json_output=$("$CKM" --json "${cmd[@]}" 2>/dev/null)

    # Extract server info
    local server_name
    server_name=$(echo "$json_output" | jq -r '.server.name // "unknown"')
    echo -e "Server: ${GREEN}${server_name}${NC}"
    echo

    # Print header
    printf "%-30s %10s %10s %10s %8s\n" "Definition" "tiktoken" "Claude" "Diff" "Ratio"
    printf "%s\n" "--------------------------------------------------------------------------------"

    local total_tiktoken=0
    local total_claude=0
    local count=0

    # Process each definition
    while IFS= read -r def; do
        local name type json_content tiktoken_count claude_count diff ratio

        name=$(echo "$def" | jq -r '.name')
        type=$(echo "$def" | jq -r '.type')
        json_content=$(echo "$def" | jq -r '.json')
        tiktoken_count=$(echo "$def" | jq -r '.tokens')

        # Get Claude token count
        claude_count=$(count_claude_tokens "$json_content")

        if [[ "$claude_count" == "error" ]]; then
            printf "%-30s %10d %10s %10s %8s\n" "${type}:${name:0:20}" "$tiktoken_count" "ERROR" "-" "-"
            continue
        fi

        diff=$((claude_count - tiktoken_count))
        if [[ $tiktoken_count -gt 0 ]]; then
            ratio=$(awk "BEGIN {printf \"%.2f\", $claude_count / $tiktoken_count}")
        else
            ratio="N/A"
        fi

        # Colour the diff
        local diff_colour="$NC"
        if [[ $diff -gt 0 ]]; then
            diff_colour="$RED"
        elif [[ $diff -lt 0 ]]; then
            diff_colour="$GREEN"
        fi

        printf "%-30s %10d %10d ${diff_colour}%+10d${NC} %8s\n" \
            "${type}:${name:0:20}" "$tiktoken_count" "$claude_count" "$diff" "${ratio}x"

        total_tiktoken=$((total_tiktoken + tiktoken_count))
        total_claude=$((total_claude + claude_count))
        count=$((count + 1))

    done < <(echo "$json_output" | jq -c '.definitions[]')

    # Print totals
    printf "%s\n" "--------------------------------------------------------------------------------"

    local total_diff=$((total_claude - total_tiktoken))
    local total_ratio
    if [[ $total_tiktoken -gt 0 ]]; then
        total_ratio=$(awk "BEGIN {printf \"%.2f\", $total_claude / $total_tiktoken}")
    else
        total_ratio="N/A"
    fi

    local diff_colour="$NC"
    if [[ $total_diff -gt 0 ]]; then
        diff_colour="$RED"
    elif [[ $total_diff -lt 0 ]]; then
        diff_colour="$GREEN"
    fi

    printf "%-30s %10d %10d ${diff_colour}%+10d${NC} %8s\n" \
        "TOTAL ($count items)" "$total_tiktoken" "$total_claude" "$total_diff" "${total_ratio}x"

    echo
    echo -e "${BLUE}Summary:${NC}"
    echo "  tiktoken (cl100k_base): $total_tiktoken tokens"
    echo "  Claude (${MODEL}): $total_claude tokens"
    echo "  Difference: $total_diff tokens (${total_ratio}x ratio)"
}

# Main
check_deps
build_ckm

if [[ $# -eq 0 ]]; then
    # Default test server
    validate npx -y @modelcontextprotocol/server-memory
else
    validate "$@"
fi
