package main

import (
	"testing"

	"github.com/go-eslab/persim/system"
)

func BenchmarkCorrelate(b *testing.B) {
	_, app, _ := system.Load("fixtures/002_020.tgff")

	for i := 0; i < b.N; i++ {
		correlate(app, 2)
	}
}
