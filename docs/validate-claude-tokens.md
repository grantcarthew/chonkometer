# Token Validation Report: tiktoken vs Claude

This document compares token counts from tiktoken (cl100k_base encoding) against
Claude's official tokenizer via the Vertex AI count-tokens API.

## Purpose

Chonkometer uses tiktoken for token counting because it's fast and doesn't require
API access. This validation measures how accurate tiktoken is compared to Claude's
actual tokenizer, helping users understand the margin of error.

## Test Run

- **Date:** 2026-01-15 12:26:40 AEST
- **Claude Model:** claude-3-haiku@20240307
- **tiktoken Encoding:** cl100k_base
- **API Region:** us-east5

## Summary

| Server | Tools | tiktoken | Claude | Diff | Ratio |
|--------|------:|----------|--------|------|-------|
| Memory | 9 | 3483 | 4243 | +760 | 1.22x |
| Sequential Thinking | 1 | 1183 | 1400 | +217 | 1.18x |
| Filesystem | 14 | 3752 | 4589 | +837 | 1.22x |
| Everything | 26 | 2630 | 3321 | +691 | 1.26x |
| GitHub | 26 | 5898 | 7307 | +1409 | 1.24x |
| Puppeteer | 8 | 896 | 1108 | +212 | 1.24x |
| Playwright | 22 | 4373 | 5399 | +1026 | 1.23x |
| **TOTAL** | | **22215** | **27367** | **5152** | **1.23x** |

## Analysis

### Key Findings

- **Average Ratio:** 1.23x - tiktoken undercounts by approximately 19% compared to Claude's tokenizer
- **Servers Tested:** 7
- **Total Definitions:** 106

### Implications

1. **tiktoken undercounts tokens** - Claude's tokenizer produces higher counts than tiktoken's cl100k_base encoding
2. **Consistent ratio** - The ~1.2x ratio appears consistent across different MCP servers
3. **Conservative estimates** - Users should multiply tiktoken counts by ~1.2 for more accurate Claude estimates

### Recommendation

For Claude Code users, the "In-context" estimate should apply a correction factor
based on these findings. A multiplier of approximately 1.2x on raw token counts
would provide more accurate estimates.


## Detailed Results

### Memory

Server: `memory-server`

| Definition | Type | tiktoken | Claude | Diff |
|------------|------|----------|--------|------|
| create_entities | tool | 444 | 541 | +97 |
| create_relations | tool | 433 | 523 | +90 |
| add_observations | tool | 371 | 458 | +87 |
| delete_entities | tool | 217 | 270 | +53 |
| delete_observations | tool | 298 | 363 | +65 |
| delete_relations | tool | 321 | 392 | +71 |
| read_graph | tool | 429 | 521 | +92 |
| search_nodes | tool | 482 | 583 | +101 |
| open_nodes | tool | 488 | 592 | +104 |
| **Total** | | **3483** | **4243** | **760** |

### Sequential Thinking

Server: `sequential-thinking-server`

| Definition | Type | tiktoken | Claude | Diff |
|------------|------|----------|--------|------|
| sequentialthinking | tool | 1183 | 1400 | +217 |
| **Total** | | **1183** | **1400** | **217** |

### Filesystem

Server: `secure-filesystem-server`

| Definition | Type | tiktoken | Claude | Diff |
|------------|------|----------|--------|------|
| read_file | tool | 257 | 317 | +60 |
| read_text_file | tool | 335 | 396 | +61 |
| read_media_file | tool | 307 | 387 | +80 |
| read_multiple_files | tool | 282 | 337 | +55 |
| write_file | tool | 239 | 297 | +58 |
| edit_file | tool | 354 | 434 | +80 |
| create_directory | tool | 233 | 284 | +51 |
| list_directory | tool | 225 | 275 | +50 |
| list_directory_with_sizes | tool | 280 | 343 | +63 |
| directory_tree | tool | 278 | 342 | +64 |
| move_file | tool | 247 | 299 | +52 |
| search_files | tool | 304 | 371 | +67 |
| get_file_info | tool | 221 | 272 | +51 |
| list_allowed_directories | tool | 190 | 235 | +45 |
| **Total** | | **3752** | **4589** | **837** |

### Everything

Server: `mcp-servers/everything`

| Definition | Type | tiktoken | Claude | Diff |
|------------|------|----------|--------|------|
| echo | tool | 109 | 139 | +30 |
| get-annotated-message | tool | 182 | 223 | +41 |
| get-env | tool | 73 | 94 | +21 |
| get-resource-links | tool | 136 | 167 | +31 |
| get-resource-reference | tool | 156 | 195 | +39 |
| get-structured-content | tool | 276 | 338 | +62 |
| get-sum | tool | 136 | 171 | +35 |
| get-tiny-image | tool | 71 | 93 | +22 |
| gzip-file-as-resource | tool | 295 | 358 | +63 |
| toggle-simulated-logging | tool | 78 | 102 | +24 |
| toggle-subscriber-updates | tool | 74 | 96 | +22 |
| trigger-long-running-operation | tool | 151 | 186 | +35 |
| get-roots-list | tool | 89 | 111 | +22 |
| simple-prompt | prompt | 30 | 42 | +12 |
| args-prompt | prompt | 91 | 113 | +22 |
| completable-prompt | prompt | 101 | 121 | +20 |
| resource-prompt | prompt | 100 | 122 | +22 |
| architecture.md | resource | 50 | 68 | +18 |
| extension.md | resource | 50 | 68 | +18 |
| features.md | resource | 49 | 68 | +19 |
| how-it-works.md | resource | 58 | 80 | +22 |
| instructions.md | resource | 50 | 68 | +18 |
| startup.md | resource | 50 | 68 | +18 |
| structure.md | resource | 50 | 68 | +18 |
| Dynamic Text Resource | template | 61 | 78 | +17 |
| Dynamic Blob Resource | template | 64 | 84 | +20 |
| **Total** | | **2630** | **3321** | **691** |

### GitHub

Server: `github-mcp-server`

| Definition | Type | tiktoken | Claude | Diff |
|------------|------|----------|--------|------|
| create_or_update_file | tool | 285 | 348 | +63 |
| search_repositories | tool | 169 | 206 | +37 |
| create_repository | tool | 176 | 218 | +42 |
| get_file_contents | tool | 193 | 237 | +44 |
| push_files | tool | 301 | 371 | +70 |
| create_issue | tool | 217 | 270 | +53 |
| create_pull_request | tool | 316 | 381 | +65 |
| fork_repository | tool | 168 | 205 | +37 |
| create_branch | tool | 198 | 242 | +44 |
| list_commits | tool | 159 | 200 | +41 |
| list_issues | tool | 280 | 352 | +72 |
| update_issue | tool | 262 | 327 | +65 |
| add_issue_comment | tool | 151 | 194 | +43 |
| search_code | tool | 172 | 218 | +46 |
| search_issues | tool | 260 | 317 | +57 |
| search_users | tool | 204 | 258 | +54 |
| get_issue | tool | 135 | 173 | +38 |
| get_pull_request | tool | 162 | 204 | +42 |
| list_pull_requests | tool | 376 | 456 | +80 |
| create_pull_request_review | tool | 591 | 722 | +131 |
| merge_pull_request | tool | 261 | 325 | +64 |
| get_pull_request_files | tool | 166 | 209 | +43 |
| get_pull_request_status | tool | 168 | 211 | +43 |
| update_pull_request_branch | tool | 201 | 250 | +49 |
| get_pull_request_comments | tool | 164 | 207 | +43 |
| get_pull_request_reviews | tool | 163 | 206 | +43 |
| **Total** | | **5898** | **7307** | **1409** |

### Puppeteer

Server: `example-servers/puppeteer`

| Definition | Type | tiktoken | Claude | Diff |
|------------|------|----------|--------|------|
| puppeteer_navigate | tool | 184 | 219 | +35 |
| puppeteer_screenshot | tool | 214 | 253 | +39 |
| puppeteer_click | tool | 83 | 106 | +23 |
| puppeteer_fill | tool | 108 | 136 | +28 |
| puppeteer_select | tool | 113 | 141 | +28 |
| puppeteer_hover | tool | 83 | 107 | +24 |
| puppeteer_evaluate | tool | 82 | 104 | +22 |
| Browser console logs | resource | 29 | 42 | +13 |
| **Total** | | **896** | **1108** | **212** |

### Playwright

Server: `Playwright`

| Definition | Type | tiktoken | Claude | Diff |
|------------|------|----------|--------|------|
| browser_close | tool | 94 | 122 | +28 |
| browser_resize | tool | 163 | 206 | +43 |
| browser_console_messages | tool | 179 | 225 | +46 |
| browser_handle_dialog | tool | 166 | 207 | +41 |
| browser_evaluate | tool | 221 | 269 | +48 |
| browser_file_upload | tool | 157 | 196 | +39 |
| browser_fill_form | tool | 350 | 428 | +78 |
| browser_install | tool | 117 | 145 | +28 |
| browser_press_key | tool | 154 | 192 | +38 |
| browser_type | tool | 281 | 339 | +58 |
| browser_navigate | tool | 136 | 171 | +35 |
| browser_navigate_back | tool | 99 | 127 | +28 |
| browser_network_requests | tool | 155 | 197 | +42 |
| browser_run_code | tool | 199 | 241 | +42 |
| browser_take_screenshot | tool | 383 | 449 | +66 |
| browser_snapshot | tool | 145 | 183 | +38 |
| browser_click | tool | 319 | 396 | +77 |
| browser_drag | tool | 257 | 314 | +57 |
| browser_hover | tool | 174 | 219 | +45 |
| browser_select_option | tool | 232 | 284 | +52 |
| browser_tabs | tool | 198 | 247 | +49 |
| browser_wait_for | tool | 194 | 242 | +48 |
| **Total** | | **4373** | **5399** | **1026** |

## Methodology

1. Each MCP server is started via `npx`
2. `chonkometer --json` fetches all tool/prompt/resource definitions
3. Each definition's JSON is sent to the Vertex AI Claude count-tokens API
4. Results are compared against tiktoken's cl100k_base counts
5. Ratios and differences are calculated

### Limitations

- Only tests JSON definition content, not the full system prompt wrapper
- Claude Code may add additional formatting overhead not captured here
- Different Claude models may tokenize slightly differently

---

*Generated by `scripts/generate-validation-report.sh`*
