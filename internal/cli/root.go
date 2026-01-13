// Package cli provides the command-line interface for chonkometer.
package cli

import (
	"context"
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/gcarthew/chonkometer/internal/mcp"
	"github.com/gcarthew/chonkometer/internal/tokens"
	"github.com/spf13/cobra"
)

// Execute runs the root command.
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}

var rootCmd = &cobra.Command{
	Use:   "ckm <command> [args...]",
	Short: "Measure MCP server token consumption",
	Long: `Chonkometer measures the token usage of MCP (Model Context Protocol) servers
before installing them. It connects to a server, fetches all definitions
(tools, prompts, resources, templates), and counts the tokens.

Example:
  ckm npx -y @modelcontextprotocol/server-everything
  ckm npx @anthropic/mcp-server-memory
  ckm go run ./cmd/my-mcp-server`,
	Version:           Version,
	Args:              cobra.MinimumNArgs(1),
	DisableAutoGenTag: true,
	SilenceUsage:      true,
	RunE:              run,
}

func init() {
	rootCmd.SetVersionTemplate("ckm version {{.Version}}\n")
	// Disable flag parsing after the first positional argument
	// so flags like -y are passed to the subprocess command
	rootCmd.Flags().SetInterspersed(false)
}

// categoryResult holds token counts for a category.
type categoryResult struct {
	name   string
	count  int
	tokens int
	items  []itemResult
}

type itemResult struct {
	name   string
	tokens int
}

func run(cmd *cobra.Command, args []string) error {
	ctx := context.Background()

	// Initialize token counter
	counter, err := tokens.NewCounter()
	if err != nil {
		return fmt.Errorf("initializing token counter: %w", err)
	}

	// Fetch definitions from MCP server
	result, err := mcp.FetchDefinitions(ctx, args[0], args[1:]...)
	if err != nil {
		return fmt.Errorf("fetching definitions: %w", err)
	}

	// Count tokens for each category
	categories := []categoryResult{
		countCategory("Tools", result.Tools, counter),
		countCategory("Prompts", result.Prompts, counter),
		countCategory("Resources", result.Resources, counter),
		countCategory("Templates", result.Templates, counter),
	}

	// Print results
	printResults(result.Server, categories, result.Warnings)

	return nil
}

func countCategory(name string, defs []mcp.Definition, counter *tokens.Counter) categoryResult {
	result := categoryResult{name: name}
	for _, def := range defs {
		tokenCount := counter.Count(def.JSON)
		result.count++
		result.tokens += tokenCount
		result.items = append(result.items, itemResult{
			name:   def.Name,
			tokens: tokenCount,
		})
	}
	// Sort items by token count descending
	sort.Slice(result.items, func(i, j int) bool {
		return result.items[i].tokens > result.items[j].tokens
	})
	return result
}

func printResults(server mcp.ServerInfo, categories []categoryResult, warnings []string) {
	// Print server info if available
	if server.Name != "" {
		if server.Version != "" {
			fmt.Printf("Server: %s v%s\n\n", server.Name, server.Version)
		} else {
			fmt.Printf("Server: %s\n\n", server.Name)
		}
	}

	// Calculate total
	var totalTokens int
	for _, cat := range categories {
		totalTokens += cat.tokens
	}

	// Print category breakdown
	for _, cat := range categories {
		fmt.Printf("%-12s %5d    (%s tokens)\n", cat.name+":", cat.count, formatNumber(cat.tokens))
	}

	// Print separator and total
	fmt.Printf("%18s ─────────────\n", "")
	fmt.Printf("%-12s       ~%s tokens\n", "Total:", formatNumber(totalTokens))

	// Calculate Claude Code in-context estimate
	// Research from mcp-code-wrapper shows Claude Code uses ~600-700 tokens TOTAL per tool
	// including mcp__ prefix, formatting, and system prompt integration.
	// Source: https://github.com/paddo/mcp-code-wrapper
	// Chrome DevTools: 26 tools = 17,500 tokens (~673 total per tool)
	// MSSQL Database: 16 tools = 11,200 tokens (~700 total per tool)
	var toolCount, promptCount, resourceCount, templateCount int
	for _, cat := range categories {
		switch cat.name {
		case "Tools":
			toolCount = cat.count
		case "Prompts":
			promptCount = cat.count
		case "Resources":
			resourceCount = cat.count
		case "Templates":
			templateCount = cat.count
		}
	}
	// Estimate ~550 tokens total per tool, ~250 per prompt, ~50 per resource/template
	// Based on observed: terraform-mcp (10 tools, 5 prompts) = ~6.8k tokens in Claude Code
	estimated := (toolCount * 550) + (promptCount * 250) + (resourceCount * 50) + (templateCount * 50)
	fmt.Printf("%-12s       ~%s tokens (estimated)\n", "In-context:", formatNumber(estimated))

	// Print largest items from the category with most tokens
	var largestCategory *categoryResult
	for i := range categories {
		if largestCategory == nil || categories[i].tokens > largestCategory.tokens {
			largestCategory = &categories[i]
		}
	}

	if largestCategory != nil && len(largestCategory.items) > 0 {
		fmt.Printf("\nLargest %s:\n", strings.ToLower(largestCategory.name))
		limit := 3
		if len(largestCategory.items) < limit {
			limit = len(largestCategory.items)
		}
		for i := 0; i < limit; i++ {
			item := largestCategory.items[i]
			fmt.Printf("  %d. %-24s %s tokens\n", i+1, item.name, formatNumber(item.tokens))
		}
	}

	// Print warnings if any
	if len(warnings) > 0 {
		fmt.Printf("\nWarnings:\n")
		for _, w := range warnings {
			fmt.Printf("  - %s\n", w)
		}
	}
}

func formatNumber(n int) string {
	if n == 0 {
		return "0"
	}
	s := fmt.Sprintf("%d", n)
	// Add commas for thousands
	var result strings.Builder
	for i, c := range s {
		if i > 0 && (len(s)-i)%3 == 0 {
			result.WriteRune(',')
		}
		result.WriteRune(c)
	}
	return result.String()
}
