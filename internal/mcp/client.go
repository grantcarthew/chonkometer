// Package mcp provides a wrapper around the MCP SDK client for fetching server definitions.
package mcp

import (
	"context"
	"encoding/json"
	"fmt"
	"os/exec"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

// Definition represents a serialized MCP definition (tool, prompt, resource, or template).
type Definition struct {
	Type string // "tool", "prompt", "resource", or "template"
	Name string
	JSON string // JSON serialization of the definition
}

// ServerInfo contains basic information about the connected MCP server.
type ServerInfo struct {
	Name    string
	Version string
}

// FetchResult contains all definitions fetched from an MCP server.
type FetchResult struct {
	Server    ServerInfo
	Tools     []Definition
	Prompts   []Definition
	Resources []Definition
	Templates []Definition
	Warnings  []string
}

// FetchDefinitions connects to an MCP server via stdio and fetches all definitions.
func FetchDefinitions(ctx context.Context, command string, args ...string) (*FetchResult, error) {
	cmd := exec.Command(command, args...)
	transport := &mcp.CommandTransport{Command: cmd}

	client := mcp.NewClient(&mcp.Implementation{
		Name:    "chonkometer",
		Version: "1.0.0",
	}, nil)

	session, err := client.Connect(ctx, transport, nil)
	if err != nil {
		return nil, err
	}
	defer session.Close()

	result := &FetchResult{}

	// Get server info from initialization result
	if initResult := session.InitializeResult(); initResult != nil && initResult.ServerInfo != nil {
		result.Server.Name = initResult.ServerInfo.Name
		result.Server.Version = initResult.ServerInfo.Version
	}

	caps := session.InitializeResult().Capabilities

	// Fetch tools if supported
	// Use MarshalIndent for more realistic token counts (Claude uses formatted JSON)
	if caps.Tools != nil {
		for tool, err := range session.Tools(ctx, nil) {
			if err != nil {
				return nil, err
			}
			jsonBytes, err := json.MarshalIndent(tool, "", "  ")
			if err != nil {
				return nil, err
			}
			result.Tools = append(result.Tools, Definition{
				Type: "tool",
				Name: tool.Name,
				JSON: string(jsonBytes),
			})
		}
	}

	// Fetch prompts if supported
	if caps.Prompts != nil {
		for prompt, err := range session.Prompts(ctx, nil) {
			if err != nil {
				return nil, err
			}
			jsonBytes, err := json.MarshalIndent(prompt, "", "  ")
			if err != nil {
				return nil, err
			}
			result.Prompts = append(result.Prompts, Definition{
				Type: "prompt",
				Name: prompt.Name,
				JSON: string(jsonBytes),
			})
		}
	}

	// Fetch resources if supported (continue on error as some servers have quirky implementations)
	if caps.Resources != nil {
		if err := fetchResources(ctx, session, result); err != nil {
			result.Warnings = append(result.Warnings, fmt.Sprintf("resources: %v", err))
		}

		if err := fetchResourceTemplates(ctx, session, result); err != nil {
			result.Warnings = append(result.Warnings, fmt.Sprintf("templates: %v", err))
		}
	}

	return result, nil
}

func fetchResources(ctx context.Context, session *mcp.ClientSession, result *FetchResult) error {
	for resource, err := range session.Resources(ctx, nil) {
		if err != nil {
			return err
		}
		jsonBytes, err := json.MarshalIndent(resource, "", "  ")
		if err != nil {
			return err
		}
		result.Resources = append(result.Resources, Definition{
			Type: "resource",
			Name: resource.Name,
			JSON: string(jsonBytes),
		})
	}
	return nil
}

func fetchResourceTemplates(ctx context.Context, session *mcp.ClientSession, result *FetchResult) error {
	for template, err := range session.ResourceTemplates(ctx, nil) {
		if err != nil {
			return err
		}
		jsonBytes, err := json.MarshalIndent(template, "", "  ")
		if err != nil {
			return err
		}
		result.Templates = append(result.Templates, Definition{
			Type: "template",
			Name: template.Name,
			JSON: string(jsonBytes),
		})
	}
	return nil
}
