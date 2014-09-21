package main

import (
	"math"
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

func TestMeasure(t *testing.T) {
	_, app, _ := system.Load("fixtures/002_020.tgff")
	distance := measure(app)

	cases := []struct {
		i uint16
		j uint16
		d float64
	}{
		{0, 1, 1},
		{0, 7, 3},
		{0, 18, math.Sqrt(5*5 + 0.5*0.5)},
		{1, 2, math.Sqrt(1*1 + 1*1)},
		{1, 3, 1},
		{2, 3, 1},
		{3, 9, math.Sqrt(1*1 + 2*2)},
		{8, 9, 1},
	}

	for _, c := range cases {
		assert.Equal(distance[20*c.i+c.j], c.d, t)
	}
}

func TestExplore(t *testing.T) {
	_, app, _ := system.Load("fixtures/002_020.tgff")
	depth := explore(app)

	assert.Equal(depth, []uint16{
		0,
		1,
		2, 2, 2,
		3, 3, 3, 3, 3,
		4, 4, 4, 4, 4, 4, 4, 4,
		5, 5}, t)
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
