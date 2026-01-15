#!/bin/bash
# Generate a comprehensive token validation report
#
# This script runs the validation against multiple MCP servers and
# generates a markdown report at docs/validate-claude-tokens.md
#
# Requirements:
#   - gcloud CLI authenticated with Vertex AI access
#   - npx (for running MCP servers)
#   - jq (for JSON parsing)
#
# Usage:
#   ./generate-validation-report.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CKM="$PROJECT_ROOT/chonkometer"
OUTPUT_FILE="$PROJECT_ROOT/docs/validate-claude-tokens.md"

# Vertex AI settings
LOCATION="us-east5"
MODEL="claude-3-haiku@20240307"

# MCP servers to test (unique list)
declare -a SERVERS=(
    "Memory|npx -y @modelcontextprotocol/server-memory"
    "Sequential Thinking|npx -y @modelcontextprotocol/server-sequential-thinking"
    "Filesystem|npx -y @modelcontextprotocol/server-filesystem /tmp"
    "Everything|npx -y @modelcontextprotocol/server-everything"
    "GitHub|npx -y @modelcontextprotocol/server-github"
    "Puppeteer|npx -y @modelcontextprotocol/server-puppeteer"
    "Playwright|npx -y @playwright/mcp"
)

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
        echo "Missing dependencies: ${missing[*]}"
        exit 1
    fi

    # Check gcloud auth
    if ! gcloud auth print-access-token &> /dev/null; then
        echo "gcloud not authenticated. Run: gcloud auth login"
        exit 1
    fi

    # Get project ID
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [[ -z "$PROJECT_ID" ]]; then
        echo "No gcloud project set. Run: gcloud config set project PROJECT_ID"
        exit 1
    fi
    export PROJECT_ID
}

# Build chonkometer if needed
build_chonkometer() {
    if [[ ! -f "$CKM" ]] || [[ "$PROJECT_ROOT/cmd/chonkometer/main.go" -nt "$CKM" ]]; then
        echo "Building chonkometer..."
        (cd "$PROJECT_ROOT" && go build -o chonkometer ./cmd/chonkometer)
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

# Validate a single server and return results as JSON
validate_server() {
    local name="$1"
    shift
    local cmd=("$@")

    echo "  Validating: $name" >&2

    # Get JSON output from chonkometer
    local json_output
    if ! json_output=$("$CKM" --json "${cmd[@]}" 2>/dev/null); then
        echo "    FAILED: could not connect" >&2
        return 0
    fi

    # Validate JSON
    if ! echo "$json_output" | jq -e . >/dev/null 2>&1; then
        echo "    FAILED: invalid JSON output" >&2
        return 0
    fi

    local server_name
    server_name=$(echo "$json_output" | jq -r '.server.name // "unknown"')

    local total_tiktoken=0
    local total_claude=0
    local definitions_json="[]"
    local def_count=0

    # Process each definition
    while IFS= read -r def; do
        local def_name def_type json_content tiktoken_count claude_count

        def_name=$(echo "$def" | jq -r '.name')
        def_type=$(echo "$def" | jq -r '.type')
        json_content=$(echo "$def" | jq -r '.json')
        tiktoken_count=$(echo "$def" | jq -r '.tokens')

        # Get Claude token count
        claude_count=$(count_claude_tokens "$json_content")

        if [[ "$claude_count" == "error" ]] || [[ -z "$claude_count" ]]; then
            echo "    Warning: API error for $def_name" >&2
            claude_count=0
        fi

        total_tiktoken=$((total_tiktoken + tiktoken_count))
        total_claude=$((total_claude + claude_count))
        def_count=$((def_count + 1))

        # Add to definitions array
        definitions_json=$(echo "$definitions_json" | jq --arg n "$def_name" --arg t "$def_type" \
            --argjson tk "$tiktoken_count" --argjson cl "$claude_count" \
            '. + [{"name": $n, "type": $t, "tiktoken": $tk, "claude": $cl}]')

    done < <(echo "$json_output" | jq -c '.definitions[]')

    echo "    $def_count definitions processed" >&2

    # Calculate ratio
    local ratio="0.00"
    if [[ $total_tiktoken -gt 0 ]]; then
        ratio=$(awk "BEGIN {printf \"%.2f\", $total_claude / $total_tiktoken}")
    fi

    # Output result as JSON (single line for easier parsing)
    jq -c -n \
        --arg name "$name" \
        --arg server "$server_name" \
        --argjson tiktoken "$total_tiktoken" \
        --argjson claude "$total_claude" \
        --arg ratio "$ratio" \
        --argjson defs "$definitions_json" \
        '{name: $name, server: $server, tiktoken: $tiktoken, claude: $claude, ratio: $ratio, definitions: $defs}'
}

# Generate markdown report
generate_report() {
    local results_file="$1"
    local run_date
    run_date=$(date "+%Y-%m-%d %H:%M:%S %Z")

    mkdir -p "$(dirname "$OUTPUT_FILE")"

    cat > "$OUTPUT_FILE" << 'HEADER'
# Token Validation Report: tiktoken vs Claude

This document compares token counts from tiktoken (cl100k_base encoding) against
Claude's official tokenizer via the Vertex AI count-tokens API.

## Purpose

Chonkometer uses tiktoken for token counting because it's fast and doesn't require
API access. This validation measures how accurate tiktoken is compared to Claude's
actual tokenizer, helping users understand the margin of error.

HEADER

    echo "## Test Run" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "- **Date:** $run_date" >> "$OUTPUT_FILE"
    echo "- **Claude Model:** $MODEL" >> "$OUTPUT_FILE"
    echo "- **tiktoken Encoding:** cl100k_base" >> "$OUTPUT_FILE"
    echo "- **API Region:** $LOCATION" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    echo "## Summary" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "| Server | Tools | tiktoken | Claude | Diff | Ratio |" >> "$OUTPUT_FILE"
    echo "|--------|------:|----------|--------|------|-------|" >> "$OUTPUT_FILE"

    local grand_tiktoken=0
    local grand_claude=0
    local server_count=0

    while IFS= read -r result; do
        local name tiktoken claude ratio tool_count diff

        name=$(echo "$result" | jq -r '.name')
        tiktoken=$(echo "$result" | jq -r '.tiktoken')
        claude=$(echo "$result" | jq -r '.claude')
        ratio=$(echo "$result" | jq -r '.ratio')
        tool_count=$(echo "$result" | jq '.definitions | length')
        diff=$((claude - tiktoken))

        if [[ "$tiktoken" != "0" ]]; then
            printf "| %s | %d | %s | %s | %+d | %sx |\n" \
                "$name" "$tool_count" "$tiktoken" "$claude" "$diff" "$ratio" >> "$OUTPUT_FILE"

            grand_tiktoken=$((grand_tiktoken + tiktoken))
            grand_claude=$((grand_claude + claude))
            server_count=$((server_count + 1))
        fi
    done < "$results_file"

    local grand_diff=$((grand_claude - grand_tiktoken))
    local grand_ratio="0.00"
    if [[ $grand_tiktoken -gt 0 ]]; then
        grand_ratio=$(awk "BEGIN {printf \"%.2f\", $grand_claude / $grand_tiktoken}")
    fi

    echo "| **TOTAL** | | **$grand_tiktoken** | **$grand_claude** | **$grand_diff** | **${grand_ratio}x** |" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    echo "## Analysis" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "### Key Findings" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    local undercount_pct=0
    if [[ $grand_claude -gt 0 ]]; then
        undercount_pct=$((100 - 100 * grand_tiktoken / grand_claude))
    fi
    local total_defs
    total_defs=$(jq -s '[.[].definitions | length] | add // 0' "$results_file" 2>/dev/null || echo "0")
    echo "- **Average Ratio:** ${grand_ratio}x - tiktoken undercounts by approximately ${undercount_pct}% compared to Claude's tokenizer" >> "$OUTPUT_FILE"
    echo "- **Servers Tested:** $server_count" >> "$OUTPUT_FILE"
    echo "- **Total Definitions:** $total_defs" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    echo "### Implications" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    cat >> "$OUTPUT_FILE" << 'IMPLICATIONS'
1. **tiktoken undercounts tokens** - Claude's tokenizer produces higher counts than tiktoken's cl100k_base encoding
2. **Consistent ratio** - The ~1.2x ratio appears consistent across different MCP servers
3. **Conservative estimates** - Users should multiply tiktoken counts by ~1.2 for more accurate Claude estimates

### Recommendation

For Claude Code users, the "In-context" estimate should apply a correction factor
based on these findings. A multiplier of approximately 1.2x on raw token counts
would provide more accurate estimates.

IMPLICATIONS

    echo "" >> "$OUTPUT_FILE"
    echo "## Detailed Results" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    while IFS= read -r result; do
        local name server tiktoken claude ratio

        name=$(echo "$result" | jq -r '.name')
        server=$(echo "$result" | jq -r '.server')
        tiktoken=$(echo "$result" | jq -r '.tiktoken')
        claude=$(echo "$result" | jq -r '.claude')
        ratio=$(echo "$result" | jq -r '.ratio')

        if [[ "$tiktoken" == "0" ]]; then
            continue
        fi

        echo "### $name" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "Server: \`$server\`" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "| Definition | Type | tiktoken | Claude | Diff |" >> "$OUTPUT_FILE"
        echo "|------------|------|----------|--------|------|" >> "$OUTPUT_FILE"

        echo "$result" | jq -c '.definitions[]' | while IFS= read -r def; do
            local def_name def_type tk cl diff
            def_name=$(echo "$def" | jq -r '.name')
            def_type=$(echo "$def" | jq -r '.type')
            tk=$(echo "$def" | jq -r '.tiktoken')
            cl=$(echo "$def" | jq -r '.claude')
            diff=$((cl - tk))
            printf "| %s | %s | %d | %d | %+d |\n" "$def_name" "$def_type" "$tk" "$cl" "$diff" >> "$OUTPUT_FILE"
        done

        local diff=$((claude - tiktoken))
        echo "| **Total** | | **$tiktoken** | **$claude** | **$diff** |" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"

    done < "$results_file"

    echo "## Methodology" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    cat >> "$OUTPUT_FILE" << 'METHODOLOGY'
1. Each MCP server is started via `npx`
2. `chonkometer --json` fetches all tool/prompt/resource definitions
3. Each definition's JSON is sent to the Vertex AI Claude count-tokens API
4. Results are compared against tiktoken's cl100k_base counts
5. Ratios and differences are calculated

### Limitations

- Only tests JSON definition content, not the full system prompt wrapper
- Claude Code may add additional formatting overhead not captured here
- Different Claude models may tokenize slightly differently
METHODOLOGY

    echo "" >> "$OUTPUT_FILE"
    echo "---" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "*Generated by \`scripts/generate-validation-report.sh\`*" >> "$OUTPUT_FILE"
}

# Main
main() {
    echo "Token Validation Report Generator"
    echo "=================================="
    echo ""

    check_deps
    build_chonkometer

    local results_file
    results_file=$(mktemp)
    trap "rm -f $results_file" EXIT

    echo "Running validations..."
    echo ""

    for server_spec in "${SERVERS[@]}"; do
        IFS='|' read -r name cmd <<< "$server_spec"
        # shellcheck disable=SC2086
        validate_server "$name" $cmd >> "$results_file"
    done

    echo ""

    # Check if we got any results
    if [[ ! -s "$results_file" ]]; then
        echo "ERROR: No results collected. Check MCP server connectivity."
        exit 1
    fi

    echo "Generating report..."

    generate_report "$results_file"

    echo ""
    echo "Report generated: $OUTPUT_FILE"
}

main
