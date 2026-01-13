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
ckm npx @anthropic/mcp-server-memory
ckm npx @anthropic/terraform-mcp-server
ckm go run ./cmd/my-mcp-server

# Show version
ckm --version
```

## Example Output

```
Server: terraform-mcp-server v1.0.0

Tools:          12    (4,230 tokens)
Prompts:         0        (0 tokens)
Resources:       3      (156 tokens)
Templates:       2       (89 tokens)
                      ─────────────
Total:                 ~4,475 tokens

Largest tools:
  1. terraform_plan        1,245 tokens
  2. terraform_apply         892 tokens
  3. terraform_init          654 tokens
```

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

## Documentation Driven Development (DDD)

This project uses Documentation Driven Development. Design decisions are documented in Design Records (DRs) before or during implementation.

- DR Writing Guide: [docs/design/dr-writing-guide.md](docs/design/dr-writing-guide.md)
- Project Writing Guide: [docs/projects/p-writing-guide.md](docs/projects/p-writing-guide.md)
- Feature Development Workflow: [docs/workflow.md](docs/workflow.md)
- Design Records: [docs/design/design-records/](docs/design/design-records/)
