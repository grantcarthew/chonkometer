# chonkometer

A CLI tool to measure the token usage of MCP (Model Context Protocol) servers before installing them.

## Problem

MCP servers consume context window tokens by exposing tool definitions, prompts, and resources to the LLM. For example, the Terraform MCP server uses ~6.8k tokens just for its definitions. There's no easy way to evaluate this cost before installation.

## Installation

```bash
brew install gcarthew/tap/ckm
```

## Usage

```bash
# Measure token usage of an MCP server (runs the server as a subprocess)
ckm npx -y @modelcontextprotocol/server-memory
ckm npx -y @modelcontextprotocol/server-filesystem
ckm go run ./cmd/my-mcp-server

# Show version
ckm --version
```

## Example Output

```
Server: memory-server v0.6.3

Tools:           9    (3,483 tokens)
Prompts:         0    (0 tokens)
Resources:       0    (0 tokens)
Templates:       0    (0 tokens)
                   ─────────────
Total:             ~3,483 tokens
Claude:            ~4,284 tokens (estimate)

Largest tools:
  1. open_nodes               488 tokens
  2. search_nodes             482 tokens
  3. create_entities          444 tokens
```

## Token Accuracy

Chonkometer uses tiktoken (cl100k_base) for fast, offline token counting. Validation against Claude's official tokenizer shows tiktoken undercounts by ~19%. The "Claude" estimate applies a 1.23x correction factor.

| Server | Tools | tiktoken | Claude (actual) | chonkometer | Ratio |
|--------|------:|----------|-----------------|-------------|-------|
| Memory | 9 | 3,483 | 4,243 | 4,284 | 1.22x |
| Sequential Thinking | 1 | 1,183 | 1,400 | 1,455 | 1.18x |
| Filesystem | 14 | 3,752 | 4,589 | 4,615 | 1.22x |
| Everything | 26 | 2,630 | 3,321 | 3,235 | 1.26x |
| GitHub | 26 | 5,898 | 7,307 | 7,255 | 1.24x |
| Puppeteer | 8 | 896 | 1,108 | 1,102 | 1.24x |
| Playwright | 22 | 4,373 | 5,399 | 5,379 | 1.23x |
| **Total** | **106** | **22,215** | **27,367** | **27,324** | **1.23x** |

*Validated 2026-01-15 against Vertex AI Claude count-tokens API. See [docs/validate-claude-tokens.md](docs/validate-claude-tokens.md) for methodology.*

## Tech Stack

- Go
- Cobra (CLI framework)
- MCP Go SDK (github.com/modelcontextprotocol/go-sdk)
- tiktoken-go (token counting)

## Development

```bash
# Build
go build -o ckm ./cmd/ckm

# Build with version
go build -ldflags "-X github.com/gcarthew/chonkometer/internal/cli.Version=1.0.0" -o ckm ./cmd/ckm

# Test
go test ./...
```

---

## Documentation Driven Development

This project uses [Documentation Driven Development](https://github.com/grantcarthew/ddd-template).
