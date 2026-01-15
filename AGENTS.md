# chonkometer

CLI tool to measure MCP server token consumption before installation. Command: `chonkometer`

See <https://agents.md/> for the full AGENTS.md specification as this project matures.

## Status

Under active development.

## Active Project

Projects are stored in `.ai/projects/`. Continue by reading the active project.

Active Project: None

## Quick Reference

```bash
# Build
go build -o chonkometer ./cmd/chonkometer

# Build with version
go build -ldflags "-X github.com/gcarthew/chonkometer/internal/cli.Version=1.0.0" -o chonkometer ./cmd/chonkometer

# Test
go test ./...

# Usage
chonkometer npx -y @modelcontextprotocol/server-everything
```

---

## Documentation

- `.ai/` - AI agent working files (projects, design records, tasks)
- `.ai/workflow.md` - Feature development workflow
- `.ai/design/design-records/` - Design records
- `docs/` - Human-facing documentation
