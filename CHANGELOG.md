# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-15

### Added

- CLI tool to measure MCP server token consumption
- Token counting using tiktoken (cl100k_base) with Claude correction factor (1.23x)
- JSON output mode for validation (`--json`)
- Support for tools, prompts, resources, and resource templates
- Displays largest tools by token count

[1.0.0]: https://github.com/grantcarthew/chonkometer/releases/tag/v1.0.0
