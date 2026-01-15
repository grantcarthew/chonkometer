// Package cli provides the command-line interface for chonkometer.
package cli

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/gcarthew/chonkometer/internal/mcp"
	"github.com/gcarthew/chonkometer/internal/tokens"
	"github.com/spf13/cobra"
)

var jsonFlag bool

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
  ckm npx -y @modelcontextprotocol/server-memory
  ckm go run ./cmd/my-mcp-server`,
	Version:           Version,
	Args:              cobra.MinimumNArgs(1),
	DisableAutoGenTag: true,
	SilenceUsage:      true,
	RunE:              run,
}

func init() {
	rootCmd.SetVersionTemplate("ckm version {{.Version}}\n")
	rootCmd.Flags().BoolVar(&jsonFlag, "json", false, "output raw definitions as JSON for validation")
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

// JSON output types for --json flag.
type jsonOutput struct {
	Server      jsonServer       `json:"server,omitempty"`
	Definitions []jsonDefinition `json:"definitions"`
	Summary     jsonSummary      `json:"summary"`
}

type jsonServer struct {
	Name    string `json:"name,omitempty"`
	Version string `json:"version,omitempty"`
}

type jsonDefinition struct {
	Type   string `json:"type"`
	Name   string `json:"name"`
	JSON   string `json:"json"`
	Tokens int    `json:"tokens"`
}

type jsonSummary struct {
	Tools     int `json:"tools"`
	Prompts   int `json:"prompts"`
	Resources int `json:"resources"`
	Templates int `json:"templates"`
	Total     int `json:"total"`
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

	// JSON output mode
	if jsonFlag {
		return printJSON(result, counter)
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

func printJSON(result *mcp.FetchResult, counter *tokens.Counter) error {
	out := jsonOutput{
		Server: jsonServer{
			Name:    result.Server.Name,
			Version: result.Server.Version,
		},
	}

	// Process all definitions
	allDefs := []struct {
		typeName string
		defs     []mcp.Definition
	}{
		{"tool", result.Tools},
		{"prompt", result.Prompts},
		{"resource", result.Resources},
		{"template", result.Templates},
	}

	for _, category := range allDefs {
		for _, def := range category.defs {
			tokenCount := counter.Count(def.JSON)
			out.Definitions = append(out.Definitions, jsonDefinition{
				Type:   category.typeName,
				Name:   def.Name,
				JSON:   def.JSON,
				Tokens: tokenCount,
			})
			out.Summary.Total += tokenCount
			switch category.typeName {
			case "tool":
				out.Summary.Tools++
			case "prompt":
				out.Summary.Prompts++
			case "resource":
				out.Summary.Resources++
			case "template":
				out.Summary.Templates++
			}
		}
	}

	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	return enc.Encode(out)
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

	// Calculate Claude estimate using validated correction factor.
	// Validation against Vertex AI Claude count-tokens API shows tiktoken (cl100k_base)
	// undercounts by ~19% compared to Claude's tokenizer. See docs/validate-claude-tokens.md
	// for methodology and detailed results across 7 MCP servers and 106 definitions.
	const claudeCorrectionFactor = 1.23
	estimated := int(float64(totalTokens) * claudeCorrectionFactor)
	fmt.Printf("%-12s       ~%s tokens (estimate)\n", "Claude:", formatNumber(estimated))

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
