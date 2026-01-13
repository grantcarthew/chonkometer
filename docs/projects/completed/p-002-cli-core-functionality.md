# P-002: Core CLI Functionality

- Status: Completed
- Started: 2025-12-18
- Completed: 2026-01-13

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

- [x] `go build ./cmd/ckm` produces working binary
- [x] `ckm --version` displays version
- [x] `ckm npx -y @modelcontextprotocol/server-everything` connects and displays token counts
- [x] Output shows breakdown by category (tools, prompts, resources, templates)
- [x] Output shows total token count
- [x] `go test ./...` passes
- [x] README contains valid, working examples
- [x] AGENTS.md contains valid example
- [x] No unused imports or dead code

## Verified MCP Server Packages

These packages have been verified to exist and work with ckm:

| Package | Description |
|---------|-------------|
| `@modelcontextprotocol/server-everything` | Test server exercising all MCP features |
| `@modelcontextprotocol/server-memory` | Knowledge graph memory server |
| `@modelcontextprotocol/server-filesystem` | Filesystem access server |

## Deliverables

- [x] cmd/ckm/main.go
- [x] internal/cli/root.go
- [x] internal/cli/version.go
- [x] internal/mcp/client.go
- [x] internal/tokens/counter.go
- [x] go.mod, go.sum
- [x] README with valid usage examples
- [x] AGENTS.md with valid example
- [x] No dead code in internal/mcp/client.go

## Technical Implementation (Completed)

The following technical approach was implemented:

1. Go module initialized as `github.com/gcarthew/chonkometer`
2. Cobra root command accepts server command as positional args
3. MCP SDK client connects via `CommandTransport`
4. Session methods `Tools()`, `Prompts()`, `Resources()`, `ResourceTemplates()` fetch definitions
5. Each definition serialized to JSON with `MarshalIndent`
6. Tokens counted using tiktoken-go with cl100k_base encoding
7. Results formatted and displayed with category breakdown

## Dependencies

- github.com/modelcontextprotocol/go-sdk v1.1.0
- github.com/spf13/cobra v1.10.2
- github.com/pkoukk/tiktoken-go v0.1.8

## Resolved Questions

These questions from the original project document have been answered:

**Q: Does the MCP SDK have a ListResourceTemplates method or is it part of ListResources?**

A: The SDK has separate iterator methods: `session.Resources()` and `session.ResourceTemplates()`. Both are under the `Resources` capability.

**Q: What's the exact JSON format Claude Code uses for serialization?**

A: Unknown exactly, but `json.MarshalIndent` with 2-space indentation provides reasonable estimates. See `docs/research.md` for calibration data.

**Q: How should we handle servers that don't implement all capability types?**

A: Check `session.InitializeResult().Capabilities` before calling each method. For resources/templates, continue on error and add warnings to output.
