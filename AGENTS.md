# chonkometer

CLI tool to measure MCP server token consumption before installation. Command: `ckm`

See <https://agents.md/> for the full AGENTS.md specification as this project matures.

## Status

Under active development.

## Active Project

Projects are stored in `.ai/projects/`. Continue by reading the active project.

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

## Documentation

- `.ai/` - AI agent working files (projects, design records, tasks)
- `.ai/workflow.md` - Feature development workflow
- `.ai/design/design-records/` - Design records
- `docs/` - Human-facing documentation
