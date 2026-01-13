package tokens

import "testing"

func TestCounter(t *testing.T) {
	c, err := NewCounter()
	if err != nil {
		t.Fatalf("NewCounter() error: %v", err)
	}

	tests := []struct {
		name  string
		input string
		want  int
	}{
		{"empty", "", 0},
		{"hello", "hello", 1},
		{"hello world", "hello world", 2},
		{"json object", `{"name": "test", "description": "a test tool"}`, 14},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := c.Count(tt.input)
			if got != tt.want {
				t.Errorf("Count(%q) = %d, want %d", tt.input, got, tt.want)
			}
		})
	}
}
