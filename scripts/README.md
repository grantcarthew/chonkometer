# Scripts

Utility scripts for testing and validating chonkometer.

- [test-mcp-servers.sh](test-mcp-servers.sh) - Test chonkometer against various MCP servers
- [validate-claude-tokens.sh](validate-claude-tokens.sh) - Compare tiktoken counts against Claude's tokenizer
- [generate-validation-report.sh](generate-validation-report.sh) - Generate the token validation report

## Requirements

- `gcloud` CLI authenticated with Vertex AI access (for validation scripts)
- `npx` for running MCP servers
- `jq` for JSON parsing

## Usage

```bash
# Test against MCP servers (quick, reference, browser, thirdparty, all)
./test-mcp-servers.sh quick

# Validate a single server against Claude's tokenizer
./validate-claude-tokens.sh npx -y @modelcontextprotocol/server-memory

# Generate the full validation report
./generate-validation-report.sh
```
