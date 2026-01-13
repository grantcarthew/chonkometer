// Package tokens provides token counting functionality using tiktoken.
package tokens

import (
	"github.com/pkoukk/tiktoken-go"
)

// Counter counts tokens using the cl100k_base encoding.
type Counter struct {
	enc *tiktoken.Tiktoken
}

// NewCounter creates a new token counter with cl100k_base encoding.
func NewCounter() (*Counter, error) {
	enc, err := tiktoken.GetEncoding("cl100k_base")
	if err != nil {
		return nil, err
	}
	return &Counter{enc: enc}, nil
}

// Count returns the number of tokens in the given text.
func (c *Counter) Count(text string) int {
	tokens := c.enc.Encode(text, nil, nil)
	return len(tokens)
}
