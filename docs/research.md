# Token Counting Research

This document explains how chonkometer estimates Claude Code's actual context window usage for MCP servers.

## The Problem

When you run an MCP server through chonkometer, it fetches the raw JSON definitions (tools, prompts, resources, templates) and counts tokens using tiktoken's cl100k_base encoding.

However, Claude Code's `/context` command reports significantly higher token usage than the raw JSON would suggest. For example:

| Server | Raw JSON Tokens | Claude Code `/context` |
|--------|-----------------|------------------------|
| terraform-mcp-server | ~2,000 | ~6,800 |

This ~3.4x difference needs explanation.

## What Claude Code Adds

When Claude Code loads an MCP tool, it doesn't just inject the raw JSON. Each tool is wrapped with:

1. **Namespace prefix**: `mcp__servername__toolname` format
2. **System prompt integration**: Boilerplate text explaining how to use the tool
3. **Formatting**: Pretty-printed JSON with additional structure
4. **Tool metadata**: Description formatting, parameter documentation

This overhead is per-tool, not a simple multiplier on the total.

## Research Sources

### mcp-code-wrapper Project

Source: https://github.com/paddo/mcp-code-wrapper

This project measured actual Claude Code token consumption:

```
Chrome DevTools MCP:    17,500 tokens (26 tools)
MSSQL Database (x2):    11,200 tokens (16 tools)
```

Calculated per-tool overhead:
- Chrome DevTools: 17,500 / 26 = **673 tokens per tool**
- MSSQL Database: 11,200 / 16 = **700 tokens per tool**

Average: **~650-700 tokens per tool** total (not additional overhead, but total context usage per tool).

### Claude Code GitHub Issues

Source: https://github.com/anthropics/claude-code/issues/3406

Reported observations:
- Built-in tools: ~10,000-11,000 tokens
- With MCP servers: Additional 4,000-8,000+ tokens
- Total overhead: 10,000-20,000+ tokens on conversation start

### Direct Observation

terraform-mcp-server (10 tools, 5 prompts):
- Raw JSON tokens: ~2,018
- Claude Code `/context`: ~6,800 tokens

This gives us a calibration point for the estimate.

## Estimation Formula

Based on the research, chonkometer uses:

```
In-context = (tools x 550) + (prompts x 250) + (resources x 50) + (templates x 50)
```

### Rationale

- **Tools (~550 tokens each)**: Most overhead. Includes full input schema, description, and Claude Code wrapper.
- **Prompts (~250 tokens each)**: Less overhead than tools. Simpler structure.
- **Resources/Templates (~50 tokens each)**: Minimal overhead. Mostly just URI and description.

### Calibration

For terraform-mcp-server:
- 10 tools x 550 = 5,500
- 5 prompts x 250 = 1,250
- **Estimated: 6,750 tokens**
- **Observed: 6,800 tokens**
- **Error: ~0.7%**

## Output Interpretation

chonkometer shows two values:

```
Total:             ~2,018 tokens
In-context:        ~6,750 tokens (estimated)
```

- **Total**: Raw definition tokens. Useful for comparing MCP servers against each other.
- **In-context**: Estimated Claude Code context usage. What you'll see in `/context`.

## Limitations

1. **Estimates may vary**: Claude Code versions, model differences, and server implementations can affect actual usage.

2. **Per-tool overhead is approximate**: The 550/250/50 values are calibrated against limited data points.

3. **Doesn't include Claude Code built-in tools**: The ~10,000-11,000 tokens for Claude Code's own tools (Read, Write, Bash, etc.) are separate.

4. **MCP protocol overhead not measured**: JSON-RPC framing and protocol messages aren't counted.

## Future Improvements

- Use Claude's Token Count API directly for exact measurements
- Collect more data points from different MCP servers
- Account for tool complexity (simple vs complex input schemas)

## References

1. mcp-code-wrapper - https://github.com/paddo/mcp-code-wrapper
2. Claude Code tool loading issue - https://github.com/anthropics/claude-code/issues/3406
3. Anthropic tool use docs - https://docs.anthropic.com/en/docs/build-with-claude/tool-use
4. Token counting API - https://docs.anthropic.com/en/api/messages-count-tokens
