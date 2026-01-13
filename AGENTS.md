# chonkometer

CLI tool to measure MCP server token consumption before installation. Command: `ckm`

See <https://agents.md/> for the full AGENTS.md specification as this project matures.

## Status

Under active development.

## Active Project

Projects are stored in the docs/projects/ directory. Update this when starting a new project.

Active Project: None

## Quick Reference

```bash
# Build
go build -o ckm ./cmd/ckm

# Build with version
go build -ldflags "-X github.com/gcarthew/chonkometer/internal/cli.Version=1.0.0" -o ckm ./cmd/ckm

# Test
go test ./...

# Usage
ckm npx -y @modelcontextprotocol/server-everything
```

---

## Documentation Driven Development (DDD)

This project uses Documentation Driven Development. Design decisions are documented in Design Records (DRs) before or during implementation.

For complete DR writing guidelines: See [docs/design/dr-writing-guide.md](docs/design/dr-writing-guide.md)

For project writing guidelines: See [docs/projects/p-writing-guide.md](docs/projects/p-writing-guide.md)

For feature development workflow: See [docs/workflow.md](docs/workflow.md)

Location: `docs/design/design-records/`
