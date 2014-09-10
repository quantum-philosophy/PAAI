package main

import (
	"testing"

	"github.com/go-math/support/assert"
)

func TestNewProblem(t *testing.T) {
	p, err := newProblem("assets/002_020.json")

	assert.Success(err, t)

	assert.Equal(p.cc, uint32(2), t)
	assert.Equal(p.tc, uint32(20), t)
	assert.Equal(p.sc, uint32(29100), t)
	assert.Equal(p.ic, uint32(1), t)
	assert.Equal(p.oc, uint32(291), t)

	assert.Equal(p.sched.Mapping, []uint16{
		0, 1, 0, 0, 1, 1, 1, 0, 0, 1,
		1, 0, 0, 0, 0, 1, 1, 1, 1, 1,
	}, t)
	assert.Equal(p.sched.Order, []uint16{
		0, 1, 2, 9, 12, 16, 18, 14, 17, 13,
		15, 3, 5, 11, 19, 8, 7, 6, 4, 10,
	}, t)
	assert.AlmostEqual(p.sched.Start, []float64{
		0.000, 0.010, 0.013, 0.187, 0.265, 0.218, 0.262, 0.260, 0.242, 0.051,
		0.267, 0.237, 0.079, 0.152, 0.113, 0.170, 0.079, 0.141, 0.113, 0.242,
	}, t)
	assert.AlmostEqual(p.sched.Span(), 0.291, t)

	assert.Equal(len(p.config.StepIndex), 291, t)
	assert.Equal(p.delay[0], 0.002, t)
}