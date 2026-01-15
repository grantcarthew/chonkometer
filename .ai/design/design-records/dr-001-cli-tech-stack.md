# dr-001: CLI Tech Stack

- Date: 2025-12-18
- Status: Accepted
- Category: CLI

## Problem

chonkometer needs a technology stack for building a CLI tool that:

- Connects to MCP servers via stdio and HTTP transports
- Counts tokens in JSON-serialized definitions
- Displays formatted output in the terminal
- Distributes as a single binary via Homebrew

Stack decisions affect maintainability, performance, and development velocity.

## Decision

| Component | Choice |
|-----------|--------|
| Language | Go |
| CLI Framework | Cobra |
| MCP Client | Official MCP Go SDK |
| Token Counting | tiktoken-go |
| Output Formatting | fmt (stdlib) |
| Project Structure | cmd/chonkometer + internal/cli |
| Testing | stdlib (testing package) |
| Build | go build + ldflags |
| Distribution | Homebrew tap |

CLI binary name: `chonkometer`

## Why

Language (Go):

- Official MCP SDK available and maintained
- Single binary output, no runtime dependencies
- Excellent CLI tooling ecosystem
- Strong concurrency support for future HTTP transport

CLI Framework (Cobra):

- Industry standard (kubectl, docker, gh use it)
- Built-in shell completions, help generation
- Clean subcommand architecture if needed later
- Extensive documentation and community

MCP Client (Official SDK):

- Handles stdio message framing correctly
- Manages initialize/initialized handshake
- Typed responses for serialization
- HTTP/SSE transport available when needed
- Maintained by Anthropic, tracks protocol changes

Token Counting (tiktoken-go):

- ~95% accuracy with cl100k_base encoding
- Pure Go, no external dependencies or API calls
- Sufficient accuracy for estimation use case
- No API key management or network errors

Output Formatting (fmt):

- No dependencies for simple aligned text
- Full control over formatting
- Easy to add colours later if needed

Project Structure (cmd + internal):

- Follows Go conventions
- Separates entrypoint from logic
- internal/cli holds Cobra commands
- internal/mcp and internal/tokens for domain packages
- Room to grow without over-engineering

Testing (stdlib):

- Table-driven tests work well
- No assertion library learning curve
- Sufficient for CLI of this size

Build (go build + ldflags):

- Simple, no build tool dependencies
- Version injection via ldflags standard pattern
- Reproducible builds

Distribution (Homebrew):

- Standard macOS/Linux distribution method
- Existing tap at ../homebrew-tap/Formula/
- Single command install for users

## Trade-offs

Accept:

- tiktoken-go ~95% accuracy (not exact Claude tokenization)
- Cobra adds ~2MB to binary size
- No fancy terminal styling without additional deps
- Manual Homebrew formula updates

Gain:

- Single binary, zero runtime dependencies
- Official SDK tracks protocol changes
- Simple build process
- Fast local token counting (no API calls)
- Familiar Go tooling and patterns

## Alternatives

Language:

- Rust: No official MCP SDK, would need custom implementation
- TypeScript: Official SDK exists, but requires Node runtime
- Rejected: Go has SDK + single binary advantage

CLI Framework:

- urfave/cli: Simpler but less ecosystem support
- Kong: Struct-based, less documentation
- stdlib only: Manual flag parsing, no completions
- Rejected: Cobra's ecosystem and features worth the size

MCP Client:

- Custom JSON-RPC: Full control, ~200 lines code
- Rejected: SDK handles edge cases, protocol updates

Token Counting:

- Anthropic API: 100% accurate but needs API key, network, latency
- Heuristic (~4 chars/token): ~70% accuracy, too imprecise
- Rejected: tiktoken-go balances accuracy and simplicity

Output:

- lipgloss: Nice styling but adds dependency for simple output
- tablewriter: More structure than needed
- Rejected: fmt sufficient, can add later

## Structure

```
chonkometer/
├── cmd/chonkometer/main.go           # Entrypoint only
├── internal/
│   ├── cli/                  # Cobra commands
│   │   ├── root.go
│   │   └── version.go
│   ├── mcp/                  # MCP client wrapper
│   │   └── client.go
│   └── tokens/               # Token counting
│       └── counter.go
├── go.mod
└── README.md
```

## Version Injection

```bash
go build -ldflags "-X github.com/gcarthew/chonkometer/internal/cli.Version=1.0.0" ./cmd/chonkometer
```
