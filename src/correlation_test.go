package main

import (
	"testing"

	"github.com/go-eslab/persim/system"
	"github.com/go-math/stats/decomp"
	"github.com/go-math/support/assert"
)

func TestCorrelate(t *testing.T) {
	_, app, _ := system.Load("fixtures/002_020.tgff")
	_, _, err := decomp.CovPCA(correlate(app, index(20), 2), 20)

	assert.Success(err, t)
}

func TestAscend(t *testing.T) {
	_, app, _ := system.Load("fixtures/002_020.tgff")

	cases := []struct {
		f uint16
		t uint16
		s uint16
	}{
		{1, 0, 1},
		{2, 0, 2},
		{13, 0, 4},
		{18, 9, 2},
		{19, 0, 2},
		{0, 19, 0},
	}

	for _, c := range cases {
		assert.Equal(ascend(app, c.f, c.t), c.s, t)
	}
}

func TestAscendDescend(t *testing.T) {
	_, app, _ := system.Load("fixtures/002_020.tgff")
	steps := explore(app)

	cases := []struct {
		f uint16
		t uint16
		s uint16
	}{
		{3, 2, 2},
		{10, 3, 3},
		{14, 18, 3},
		{17, 10, 4},
	}

	for _, c := range cases {
		assert.Equal(ascendDescend(app, c.f, c.t, steps), c.s, t)
	}
}

func BenchmarkCorrelate(b *testing.B) {
	_, app, _ := system.Load("fixtures/002_020.tgff")
	index := index(20)

	for i := 0; i < b.N; i++ {
		correlate(app, index, 2)
	}
}

func index(count uint16) []uint16 {
	index := make([]uint16, count)

	for i := uint16(0); i < count; i++ {
		index[i] = i
	}

	return index
}
