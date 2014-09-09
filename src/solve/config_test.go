package main

import (
	"testing"

	"github.com/go-math/support/assert"
)

func TestConfigLoad(t *testing.T) {
	c, _ := newConfig("assets/002_020.json")

	assert.Equal(c.TimeStep, 1e-3, t)
}
