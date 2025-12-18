# P-002: Core CLI Functionality

- Status: Proposed
- Started: -

## Overview

Implement the core chonkometer CLI that connects to an MCP server via stdio transport, fetches all definitions (tools, prompts, resources, resource templates), counts tokens, and displays a formatted breakdown.

## Goals

1. Create project structure (cmd/ckm, internal/cli, internal/mcp, internal/tokens)
2. Implement MCP client wrapper using the official Go SDK
3. Implement token counting using tiktoken-go
4. Build Cobra CLI with root command for stdio transport
5. Display formatted output showing token breakdown by category

## Scope

In Scope:
- Project scaffolding (go.mod, directory structure)
- Stdio transport (CommandTransport) for subprocess-based MCP servers
- Fetching tools, prompts, resources, and resource templates
- Token counting with tiktoken-go (cl100k_base encoding)
- Formatted terminal output with category breakdown and totals
- Version flag (--version) with ldflags injection

Out of Scope:
- HTTP/SSE transport (future project)
- JSON output format (future enhancement)
- Verbose mode showing full definitions (future enhancement)
- Reading from Claude Code settings.json (future enhancement)
- Homebrew formula (separate task after initial release)

## Success Criteria

- [ ] `go build ./cmd/ckm` produces working binary
- [ ] `ckm --version` displays version
- [ ] `ckm npx @anthropic/mcp-server-memory` connects and displays token counts
- [ ] Output shows breakdown by category (tools, prompts, resources, templates)
- [ ] Output shows total token count
- [ ] `go test ./...` passes

## Deliverables

- cmd/ckm/main.go
- internal/cli/root.go
- internal/cli/version.go
- internal/mcp/client.go
- internal/tokens/counter.go
- go.mod, go.sum
- Basic README updates with actual usage examples

## Technical Approach

1. Initialize Go module as github.com/gcarthew/chonkometer
2. Create Cobra root command that accepts server command as positional args
3. Wrap MCP SDK client to connect via CommandTransport
4. Call ListTools, ListPrompts, ListResources, ListResourceTemplates
5. Serialize each definition to JSON
6. Count tokens using tiktoken-go with cl100k_base encoding
7. Format and display results

## Dependencies

- github.com/modelcontextprotocol/go-sdk/mcp
- github.com/spf13/cobra
- github.com/pkoukk/tiktoken-go

## Questions and Uncertainties

- Does the MCP SDK have a ListResourceTemplates method or is it part of ListResources?
- What's the exact JSON format Claude Code uses for serialization?
- How should we handle servers that don't implement all capability types?
