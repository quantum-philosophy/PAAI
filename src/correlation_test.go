package main

import (
	"testing"

	"github.com/go-eslab/persim/system"
	"github.com/go-math/support/assert"
)

func TestAscend(t *testing.T) {
	_, app, _ := system.Load("fixtures/002_020.tgff")

	assert.Equal(ascend(app, 0, 0), 0.0, t)
	assert.Equal(ascend(app, 1, 0), 1.0, t)
	assert.Equal(ascend(app, 2, 0), 2.0, t)
	assert.Equal(ascend(app, 13, 0), 4.0, t)
	assert.Equal(ascend(app, 18, 9), (2.0+2.0)/2.0, t)
	assert.Equal(ascend(app, 19, 0), (2.0+5.0)/2.0, t)
	assert.Equal(ascend(app, 0, 19), -1.0, t)
}

func BenchmarkCorrelate(b *testing.B) {
	_, app, _ := system.Load("fixtures/002_020.tgff")

	for i := 0; i < b.N; i++ {
		correlate(app, 2)
	}
}
