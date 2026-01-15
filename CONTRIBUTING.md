# Contributing to chonkometer

Thank you for your interest in contributing to chonkometer! This document provides guidelines and instructions for contributing.

## Quick Links

- [Issues](https://github.com/grantcarthew/chonkometer/issues) - Report bugs or request features
- [Pull Requests](https://github.com/grantcarthew/chonkometer/pulls) - Submit code changes
- [AGENTS.md](AGENTS.md) - Technical documentation for AI agents and developers

## Ways to Contribute

- Report bugs
- Suggest new features or improvements
- Improve documentation
- Submit pull requests with bug fixes or features
- Help answer questions in issues

## Reporting Bugs

When reporting bugs, please:

1. Check [existing issues](https://github.com/grantcarthew/chonkometer/issues) first
2. Provide:
   - chonkometer version: `chonkometer --version`
   - Operating system and version
   - Full command that triggered the bug
   - Complete error message or unexpected output

## Development Setup

### Prerequisites

- Go 1.23 or later
- Git

### Getting Started

```bash
# Clone the repository
git clone https://github.com/grantcarthew/chonkometer.git
cd chonkometer

# Install dependencies
go mod download

# Build the project
go build -o chonkometer ./cmd/chonkometer

# Verify installation
./chonkometer --version
```

### Project Structure

```
chonkometer/
├── cmd/chonkometer/main.go       # Entrypoint
├── internal/
│   ├── cli/              # Cobra commands
│   ├── mcp/              # MCP client wrapper
│   └── tokens/           # Token counting
├── go.mod
└── README.md
```

## Running Tests

```bash
# Run all tests
go test -v ./...

# Run with coverage
go test -v -cover ./...
```

## Code Style

### Go Conventions

- Follow standard Go formatting: `gofmt` or `goimports`
- Use Go 1.23+ features and idioms
- Keep functions focused and small
- Use descriptive variable names

### License Headers

Add MPL 2.0 header to all new `.go` files:

```go
// Copyright (c) 2025 Grant Carthew
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

package main
```

### Code Quality

Before submitting:

```bash
# Format code
gofmt -w .

# Vet code
go vet ./...

# Run tests
go test -v ./...
```

## Branch Management

- Main branch: `main`
- Feature branches: `feature/description`
- Bug fix branches: `fix/description`
- Always work on feature branches, PR to `main`

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/) style:

```
feat(cli): add JSON output format
fix(mcp): handle servers without prompts capability
docs: update installation instructions
chore(deps): update tiktoken-go
test(tokens): add token counting test cases
refactor(cli): simplify output formatting
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `chore` - Maintenance tasks, dependencies
- `test` - Test additions or changes
- `refactor` - Code restructuring without behavior change

## Pull Request Process

1. **Create an issue first** (for significant changes)
2. **Fork the repository** and create a feature branch
3. **Make your changes:**
   - Write clear, focused commits
   - Follow code style guidelines
   - Add/update tests as needed
   - Update documentation if changing CLI interface
4. **Test thoroughly:**
   - Run all tests: `go test -v ./...`
   - Build successfully: `go build ./cmd/chonkometer`
5. **Submit pull request:**
   - Reference related issue(s)
   - Describe what changed and why
   - Keep PRs focused on a single feature/fix
6. **Respond to review feedback**

## Documentation

When changing functionality:

- Update `README.md` for user-facing changes
- Update `AGENTS.md` for technical implementation details
- Add design decisions to `docs/design/design-records/` for architectural changes

## Questions or Need Help?

- Open an issue for questions
- Check [AGENTS.md](AGENTS.md) for detailed technical documentation
- Review existing code and tests for examples

## License

By contributing to chonkometer, you agree that your contributions will be licensed under the [Mozilla Public License 2.0](LICENSE).

## Code of Conduct

Be respectful, professional, and constructive in all interactions. We welcome contributors of all experience levels.
